"""Clone or update the VNotes repository."""

import logging

from installer.cmd import run
from installer.config import VNOTES_DIR, VNOTES_REPO
from installer.distro import Distro


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    git_dir = VNOTES_DIR / ".git"

    if git_dir.is_dir():
        logging.info("VNotes repository already exists. Pulling latest changes...")
        run("git", "-C", str(VNOTES_DIR), "pull")
        return

    logging.info("Cloning VNotes repository...")
    if dry_run:
        logging.info(f"[dry-run] Would clone {VNOTES_REPO} -> {VNOTES_DIR}")
        return

    run("git", "clone", VNOTES_REPO, str(VNOTES_DIR))
    logging.info("VNotes set up successfully.")
