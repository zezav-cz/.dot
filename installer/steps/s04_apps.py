"""Install Obsidian."""

import logging
from pathlib import Path

from installer.cmd import download, is_installed, run
from installer.config import APPS_OBSIDIAN
from installer.distro import Distro


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    _install_obsidian(dry_run)
    # TODO: Zotero installation to be re-added


def _install_obsidian(dry_run: bool) -> None:
    app = APPS_OBSIDIAN

    if is_installed(app.name):
        logging.info(f"{app.name} is already installed. Skipping.")
        return

    url = app.url_template.format(version=app.version)
    logging.info(f"Downloading and installing {app.name} v{app.version}...")

    if dry_run:
        logging.info(f"[dry-run] Would download {url} -> {app.install_path}")
        return

    download(url, Path(app.install_path), sudo=True)
    run("chmod", "+x", app.install_path, sudo=True)
