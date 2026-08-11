"""Update all system packages before installation."""

import logging

from installer.cmd import run
from installer.distro import Distro
from installer.errors import InstallerError


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    if distro != Distro.FEDORA:
        raise InstallerError("System update is only implemented for Fedora")

    logging.info("Updating system packages...")
    run("dnf", "update", "-y", sudo=True)
