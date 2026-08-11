"""Install Oh My Zsh and plugins."""

import logging
import os
import pwd
import shutil

from installer.cmd import is_installed, run
from installer.config import HOME, ZSH_CUSTOM, ZSH_PLUGINS
from installer.distro import Distro, get_manager
from installer.errors import InstallerError

OMZ_DIR = HOME / ".oh-my-zsh"


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    _install_oh_my_zsh(dry_run, distro)
    _install_plugins(dry_run)
    _set_default_shell(dry_run)


def _install_oh_my_zsh(dry_run: bool, distro: Distro) -> None:
    if OMZ_DIR.is_dir():
        logging.info("Oh My Zsh is already installed. Skipping.")
        return

    if not is_installed("zsh"):
        if distro == Distro.UNKNOWN:
            raise InstallerError("Cannot install zsh on unknown distro.")
        logging.info("Zsh is not installed. Installing zsh first...")
        if dry_run:
            logging.info("[dry-run] Would install zsh")
        else:
            get_manager(distro).install(["zsh"])

    logging.info("Installing Oh My Zsh...")
    if dry_run:
        logging.info("[dry-run] Would install Oh My Zsh")
        return

    run(
        "git",
        "clone",
        "--depth=1",
        "https://github.com/ohmyzsh/ohmyzsh.git",
        str(OMZ_DIR),
    )


def _install_plugins(dry_run: bool) -> None:
    for plugin_name, repo_url in ZSH_PLUGINS.items():
        plugin_dir = ZSH_CUSTOM / "plugins" / plugin_name

        if plugin_dir.is_dir():
            logging.info(f"Plugin {plugin_name} already exists. Pulling latest...")
            if not dry_run:
                run("git", "-C", str(plugin_dir), "pull")
            else:
                logging.info(f"[dry-run] Would pull latest changes for {plugin_name}")
        else:
            logging.info(f"Cloning plugin: {plugin_name}")
            if not dry_run:
                run("git", "clone", repo_url, str(plugin_dir))
            else:
                logging.info(f"[dry-run] Would clone {repo_url} -> {plugin_dir}")


def _set_default_shell(dry_run: bool) -> None:
    zsh_path = shutil.which("zsh")
    if zsh_path is None:
        logging.warning("zsh not found on PATH, skipping default shell change.")
        return

    current_shell = pwd.getpwuid(os.getuid()).pw_shell
    if current_shell == zsh_path:
        logging.info("zsh is already the default shell. Skipping.")
        return

    logging.info(f"Setting default shell to {zsh_path}...")
    if dry_run:
        logging.info(f"[dry-run] Would run: chsh -s {zsh_path}")
        return

    run("chsh", "-s", zsh_path)
