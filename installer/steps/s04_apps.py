"""Install AppImage apps: download, GPG-verify, install to PATH, desktop entry."""

import logging
import shutil
import tempfile
from pathlib import Path

from installer.cmd import download, ensure_dir, is_installed, run
from installer.config import APPIMAGE_DIR, APPS, DESKTOP_DIR, ICON_DIR, AppInstall
from installer.distro import Distro

# Pre-refactor install locations to clean up when migrating an app
LEGACY_PATHS = {
    "obsidian": Path("/usr/local/bin/obsidian"),
}


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    for app in APPS:
        _install_app(app, dry_run)
    _disable_dunst(dry_run)
    # TODO: Zotero installation to be re-added


def _disable_dunst(dry_run: bool) -> None:
    if dry_run:
        logging.info("[dry-run] Would mask dunst.service (user)")
        return
    logging.info("Masking dunst to prevent it from replacing swaync...")
    run("systemctl", "--user", "mask", "dunst.service", check=False)


def _install_app(app: AppInstall, dry_run: bool) -> None:
    _remove_legacy_install(app, dry_run)

    if is_installed(app.name):
        logging.info(f"{app.name} is already installed. Skipping.")
        return

    version = f" v{app.version}" if app.version else ""
    logging.info(f"Installing {app.display_name}{version}...")

    install_path = APPIMAGE_DIR / app.name

    if dry_run:
        logging.info(f"[dry-run] Would download {app.url} -> {install_path}")
        if app.gpg_key_url:
            logging.info(f"[dry-run] Would GPG-verify against {app.gpg_key_url}")
        if app.icon_url:
            logging.info(f"[dry-run] Would download icon {app.icon_url}")
        logging.info(f"[dry-run] Would write {DESKTOP_DIR / app.name}.desktop")
        return

    with tempfile.TemporaryDirectory(prefix=f"appimage-{app.name}-") as tmp:
        tmp_dir = Path(tmp)
        appimage = tmp_dir / f"{app.name}.AppImage"
        download(app.url, appimage)
        _verify_signature(app, appimage, tmp_dir)

        ensure_dir(APPIMAGE_DIR)
        shutil.move(appimage, install_path)
        run("chmod", "+x", str(install_path))

    icon_path = _install_icon(app)
    _install_desktop_entry(app, install_path, icon_path)
    logging.info(f"{app.display_name} installed to {install_path}")


def _remove_legacy_install(app: AppInstall, dry_run: bool) -> None:
    legacy = LEGACY_PATHS.get(app.name)
    if legacy is None or not legacy.exists():
        return
    if dry_run:
        logging.info(f"[dry-run] Would remove legacy install {legacy}")
        return
    logging.info(f"Removing legacy install {legacy}...")
    run("rm", "-f", str(legacy), sudo=True)


def _verify_signature(app: AppInstall, appimage: Path, tmp_dir: Path) -> None:
    """Verify the AppImage against the vendor's detached GPG signature."""
    if not (app.gpg_key_url and app.gpg_sig_url):
        return

    key_path = tmp_dir / "signing-key.asc"
    sig_path = tmp_dir / f"{appimage.name}.sig"
    download(app.gpg_key_url, key_path)
    download(app.gpg_sig_url, sig_path)

    run("gpg", "--import", str(key_path))
    # Raises InstallerError on a bad signature; the untrusted-key
    # warning gpg prints for a good signature is expected.
    run("gpg", "--verify", str(sig_path), str(appimage))
    logging.info(f"GPG signature of {app.name} verified.")


def _install_icon(app: AppInstall) -> Path | None:
    if app.icon_url is None:
        return None
    ext = Path(app.icon_url).suffix or ".png"
    icon_path = ICON_DIR / f"{app.name}{ext}"
    ensure_dir(ICON_DIR)
    try:
        download(app.icon_url, icon_path)
    except Exception as exc:  # noqa: BLE001 - icon is cosmetic, never fatal
        logging.warning(f"Icon download failed for {app.name}: {exc}")
        return None
    return icon_path


def _install_desktop_entry(
    app: AppInstall, install_path: Path, icon_path: Path | None
) -> None:
    lines = [
        "[Desktop Entry]",
        "Type=Application",
        f"Name={app.display_name}",
        f"Exec={install_path} %U",
        "Terminal=false",
        f"Categories={app.categories}",
    ]
    if icon_path is not None:
        lines.insert(4, f"Icon={icon_path}")
    if app.wm_class:
        lines.append(f"StartupWMClass={app.wm_class}")

    ensure_dir(DESKTOP_DIR)
    desktop_file = DESKTOP_DIR / f"{app.name}.desktop"
    desktop_file.write_text("\n".join(lines) + "\n")
    run("update-desktop-database", str(DESKTOP_DIR), check=False)
