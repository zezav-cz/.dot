"""Stow all configuration directories."""

import datetime
import logging
import os
import shutil

from installer.cmd import run
from installer.config import (
    CLAUDE_PERSONAL_DIR,
    CLAUDE_SHARED_LINKS,
    DOTFILES_DIR,
    HOME,
    LAZY_NVIM_PATH,
    LAZY_NVIM_REPO,
    STOW_NO_FOLDING,
    STOW_PACKAGES,
    TPM_PATH,
    TPM_REPO,
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

    _link_claude_shared(dry_run)
    _ensure_lazy_nvim(dry_run)
    _ensure_tpm(dry_run)


def _link_claude_shared(dry_run: bool) -> None:
    """Point the personal Claude instance at the work instance's shared assets.

    Both instances must offer the same CLAUDE.md, agents, skills and plugins;
    linking instead of copying keeps them in sync when either side changes.
    """
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    for rel, target in CLAUDE_SHARED_LINKS.items():
        link = CLAUDE_PERSONAL_DIR / rel
        if link.is_symlink() and os.readlink(link) == target:
            continue
        logging.info(f"Linking ~/.claude-personal/{rel} -> {target}")
        if dry_run:
            continue
        link.parent.mkdir(parents=True, exist_ok=True)
        if link.is_symlink():
            link.unlink()
        elif link.exists():
            link.rename(link.with_name(f"{link.name}.bak.{ts}"))
        link.symlink_to(target)


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
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        LAZY_NVIM_REPO,
        str(LAZY_NVIM_PATH),
    )


def _ensure_tpm(dry_run: bool) -> None:
    if (TPM_PATH / "tpm").is_file():
        logging.info("tpm already installed, skipping")
        return
    if TPM_PATH.exists():
        logging.info("tpm directory incomplete, removing")
        if not dry_run:
            shutil.rmtree(TPM_PATH)
    logging.info("Cloning tpm (tmux plugin manager)")
    run("git", "clone", TPM_REPO, str(TPM_PATH))
