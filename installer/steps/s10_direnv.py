"""Install direnv (+ nix-direnv) for repos with a `.envrc` (e.g. `use flake`).

zsh integration lives in stow/zsh/.zshrc (`eval "$(direnv hook zsh)"`) —
this step only installs the binaries and the nix-direnv cache config.
"""

import logging
from pathlib import Path

from installer.cmd import is_installed, run
from installer.distro import Distro, get_manager
from installer.errors import InstallerError

DIRENV_CONFIG_DIR = Path.home() / ".config" / "direnv"
DIRENVRC = DIRENV_CONFIG_DIR / "direnvrc"
NIX_DIRENVRC_LINE = 'source "$HOME/.nix-profile/share/nix-direnv/direnvrc"\n'


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    _install_direnv(dry_run, distro)
    _install_nix_direnv(dry_run)
    _write_direnvrc(dry_run)


def _install_direnv(dry_run: bool, distro: Distro) -> None:
    if is_installed("direnv"):
        logging.info("direnv is already installed. Skipping.")
        return

    logging.info("Installing direnv...")
    if dry_run:
        logging.info("[dry-run] Would install direnv via the system package manager")
        return

    if distro == Distro.UNKNOWN:
        raise InstallerError("Cannot install direnv on unknown distro.")
    get_manager(distro).install(["direnv"])


def _install_nix_direnv(dry_run: bool) -> None:
    if not is_installed("nix"):
        logging.warning("Nix not found — skipping nix-direnv (run the nix step first).")
        return

    nix_direnv_path = Path.home() / ".nix-profile" / "share" / "nix-direnv" / "direnvrc"
    if nix_direnv_path.is_file():
        logging.info("nix-direnv is already installed. Skipping.")
        return

    logging.info("Installing nix-direnv via `nix profile install`...")
    if dry_run:
        logging.info("[dry-run] Would run: nix profile install nixpkgs#nix-direnv")
        return

    run("nix", "profile", "install", "nixpkgs#nix-direnv")


def _write_direnvrc(dry_run: bool) -> None:
    if DIRENVRC.is_file() and DIRENVRC.read_text() == NIX_DIRENVRC_LINE:
        logging.info(f"{DIRENVRC} already configured. Skipping.")
        return

    logging.info(f"Writing {DIRENVRC}...")
    if dry_run:
        logging.info(f"[dry-run] Would write nix-direnv source line to {DIRENVRC}")
        return

    DIRENV_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    DIRENVRC.write_text(NIX_DIRENVRC_LINE)
