"""Enable COPR repos and add VS Code repository (Fedora only)."""

import logging
from pathlib import Path

from installer.cmd import run
from installer.config import COPR_REPOS, VSCODE_REPO
from installer.distro import Distro
from installer.errors import InstallerError

VSCODE_REPO_FILE = Path("/etc/yum.repos.d/vscode.repo")


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    if distro != Distro.FEDORA:
        raise InstallerError("Repo setup is only implemented for Fedora")

    logging.info("Installing dnf-plugins-core...")
    run("dnf", "install", "-y", "dnf-plugins-core", sudo=True)

    for repo in COPR_REPOS:
        logging.info(f"Enabling COPR repo: {repo}")
        run("dnf", "copr", "enable", repo, "-y", sudo=True)

    # VS Code repository
    logging.info("Adding VS Code repository...")
    run(
        "rpm",
        "--import",
        "https://packages.microsoft.com/keys/microsoft.asc",
        sudo=True,
    )

    if VSCODE_REPO_FILE.exists() and not dry_run:
        logging.info("VS Code repo file already exists. Overwriting.")

    run("tee", str(VSCODE_REPO_FILE), sudo=True, input=VSCODE_REPO)
