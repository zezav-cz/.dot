"""Install system packages for the detected distro."""

import logging

from installer.config import PACKAGES
from installer.distro import Distro, get_manager
from installer.errors import InstallerError


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    pkg_list = PACKAGES.get(distro.value)
    if not pkg_list:
        raise InstallerError(f"Package list for distro {distro.value} is incomplete")

    logging.info(f"Installing {len(pkg_list)} packages for {distro.value}...")
    manager = get_manager(distro)
    manager.install(pkg_list)
