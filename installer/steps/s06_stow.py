"""Stow all configuration directories."""

import datetime
import logging
import shutil

from installer.cmd import run
from installer.config import (
    DOTFILES_DIR,
    HOME,
    LAZY_NVIM_PATH,
    LAZY_NVIM_REPO,
    STOW_NO_FOLDING,
    STOW_PACKAGES,
)
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
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup = HOME / f".zshrc.bak.{ts}"
        logging.info(f"Backing up ~/.zshrc to ~/{backup.name}")
        if not dry_run:
            zshrc.rename(backup)

    for pkg in STOW_PACKAGES:
        logging.info(f"Stowing {pkg}")
        run("stow", "-d", str(STOW_DIR), "-t", str(HOME), "-v", pkg)

    for pkg in STOW_NO_FOLDING:
        logging.info(f"Stowing {pkg} (--no-folding)")
        run("stow", "-d", str(STOW_DIR), "-t", str(HOME), "-v", pkg, "--no-folding")

    _ensure_lazy_nvim(dry_run)


def _ensure_lazy_nvim(dry_run: bool) -> None:
    if (LAZY_NVIM_PATH / "lua").is_dir():
        logging.info("lazy.nvim already installed, skipping")
        return
    if LAZY_NVIM_PATH.exists():
        logging.info("lazy.nvim directory incomplete, removing")
        if not dry_run:
            shutil.rmtree(LAZY_NVIM_PATH)
    logging.info("Cloning lazy.nvim")
    run(
        "git", "clone", "--filter=blob:none", "--branch=stable",
        LAZY_NVIM_REPO, str(LAZY_NVIM_PATH),
    )
