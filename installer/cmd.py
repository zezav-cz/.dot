"""Thin subprocess wrapper with dry-run support."""

from __future__ import annotations

import logging
import shutil
import subprocess
import time
from pathlib import Path
from typing import TYPE_CHECKING

from installer.errors import InstallerError

if TYPE_CHECKING:
    from installer.distro import Distro

# Set by the entry point based on CLI flags
DRY_RUN = False


def run(
    *args: str,
    sudo: bool = False,
    check: bool = True,
    capture: bool = False,
    input: str | None = None,
) -> subprocess.CompletedProcess:
    """Run a command, optionally with sudo.

    Args:
        *args: Command and arguments.
        sudo: Prepend 'sudo' to the command.
        check: Raise on non-zero exit code.
        capture: Return stdout instead of streaming it.
        input: String to feed to the process's stdin.
    """
    cmd = ["sudo", *args] if sudo else list(args)
    label = " ".join(cmd)

    if DRY_RUN:
        logging.info(f"[dry-run] $ {label}")
        return subprocess.CompletedProcess(cmd, 0, stdout="", stderr="")

    logging.debug(f"$ {label}")

    if capture:
        result = subprocess.run(cmd, capture_output=True, text=True, input=input)
    else:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            input=input,
        )
        if result.stdout:
            for line in result.stdout.splitlines():
                logging.debug(line)

    if check and result.returncode != 0:
        logging.error(f"Command failed (exit {result.returncode}): {label}")
        if result.stdout:
            for line in result.stdout.splitlines():
                logging.debug(line)
        if result.stderr:
            for line in result.stderr.splitlines():
                logging.debug(line)
        raise InstallerError(f"Command failed (exit {result.returncode}): {label}")

    return result


def is_installed(name: str) -> bool:
    """Check if a command is available on PATH."""
    return shutil.which(name) is not None


def download(url: str, dest: Path, sudo: bool = False, retries: int = 3) -> None:
    """Download a file with wget, retrying on failure."""
    for attempt in range(1, retries + 1):
        try:
            run("wget", "-q", url, "-O", str(dest), sudo=sudo)
            return
        except InstallerError:
            if attempt == retries:
                raise
            logging.warning(
                f"Download failed (attempt {attempt}/{retries}), retrying..."
            )
            time.sleep(2 * attempt)


def ensure_dir(path: Path) -> None:
    """Create directory if it doesn't exist."""
    if DRY_RUN:
        logging.info(f"[dry-run] mkdir -p {path}")
        return
    path.mkdir(parents=True, exist_ok=True)


def package_installed(name: str, distro: Distro) -> bool:
    """Check if a system package is installed using the distro's package tool."""
    from installer.distro import Distro as _Distro

    check_cmds = {
        _Distro.FEDORA: ("rpm", "-q", name),
        _Distro.DEBIAN: ("dpkg", "-s", name),
        _Distro.ARCH: ("pacman", "-Qi", name),
    }
    args = check_cmds.get(distro)
    if args is None:
        logging.warning(f"Cannot check packages on {distro.value}")
        return False
    result = run(*args, check=False, capture=True)
    return result.returncode == 0
