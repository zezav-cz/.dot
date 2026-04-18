"""Stow all configuration directories."""

import logging

from installer.cmd import run
from installer.config import DOTFILES_DIR, HOME, STOW_NO_FOLDING, STOW_PACKAGES
from installer.distro import Distro
from installer.errors import InstallerError

STOW_DIR = DOTFILES_DIR / "stow"


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    # Validate that every declared stow package has a directory in the repo.
    for pkg in STOW_PACKAGES + STOW_NO_FOLDING:
        if not (STOW_DIR / pkg).is_dir():
            raise InstallerError(f"Stow package directory not found: stow/{pkg}")

    # Handle plain .zshrc that would conflict with stow
    zshrc = HOME / ".zshrc"
    if zshrc.is_file() and not zshrc.is_symlink():
        logging.info("Removing plain ~/.zshrc (will be replaced by stow symlink)")
        if not dry_run:
            zshrc.unlink()

    for pkg in STOW_PACKAGES:
        logging.info(f"Stowing {pkg}")
        run("stow", "-d", str(STOW_DIR), "-t", str(HOME), "-v", pkg)

    for pkg in STOW_NO_FOLDING:
        logging.info(f"Stowing {pkg} (--no-folding)")
        run("stow", "-d", str(STOW_DIR), "-t", str(HOME), "-v", pkg, "--no-folding")
