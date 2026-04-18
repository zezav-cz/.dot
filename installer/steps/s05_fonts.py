"""Download and install fonts (Nerd Fonts + Font Awesome)."""

import logging
import zipfile
from pathlib import Path

from installer.cmd import download, ensure_dir, run
from installer.config import EXTRA_FONTS, FONTS_DIR
from installer.distro import Distro
from installer.errors import InstallerError


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    for font in EXTRA_FONTS:
        _install_font(
            font.name,
            font.url,
            FONTS_DIR / font.extract_dir,
            dry_run,
            zip_name=font.zip_name,
        )

    logging.info("Updating font cache...")
    if not dry_run:
        run("fc-cache", "-f")


def _install_font(
    name: str, url: str, dest_dir: Path, dry_run: bool, zip_name: str | None = None
) -> None:
    """Download and extract a font zip archive."""
    zip_file = dest_dir.parent / (zip_name or f"{name}.zip")

    if dest_dir.is_dir() and any(dest_dir.iterdir()):
        logging.info(f"Font {name} is already installed. Skipping.")
        return

    logging.info(f"Downloading font: {name}")

    if dry_run:
        logging.info(f"[dry-run] Would download {url} -> {dest_dir}")
        return

    try:
        ensure_dir(dest_dir.parent)
        download(url, zip_file)
        ensure_dir(dest_dir)
        with zipfile.ZipFile(zip_file) as zf:
            zf.extractall(dest_dir)
        zip_file.unlink()
        logging.info(f"Successfully installed {name}")
    except (InstallerError, zipfile.BadZipFile, OSError) as e:
        logging.error(f"Failed to install {name}: {e}")
        if zip_file.exists():
            zip_file.unlink()
        raise
