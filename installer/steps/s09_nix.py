"""Install Nix (Determinate Systems installer) for flake-based repos.

Lives entirely under /nix, side by side with mise/apt — doesn't touch either.
"""

import logging

from installer.cmd import is_installed, run
from installer.distro import Distro

NIX_INSTALL_URL = "https://install.determinate.systems/nix"


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    if is_installed("nix"):
        logging.info("Nix is already installed. Skipping.")
        return

    logging.info("Installing Nix via the Determinate Systems installer...")
    if dry_run:
        logging.info(
            f"[dry-run] Would run: curl -sSf -L {NIX_INSTALL_URL} | "
            "sh -s -- install --no-confirm"
        )
        return

    script = run(
        "curl",
        "--proto",
        "=https",
        "--tlsv1.2",
        "-sSf",
        "-L",
        NIX_INSTALL_URL,
        capture=True,
    )
    run("sh", "-s", "--", "install", "--no-confirm", input=script.stdout)
    logging.info(
        "Nix installed. Open a new shell, or run: "
        ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    )
