"""Distro detection and package manager abstraction."""

import logging
from abc import ABC, abstractmethod
from enum import Enum
from pathlib import Path

from installer import cmd
from installer.errors import InstallerError


class Distro(Enum):
    FEDORA = "fedora"
    DEBIAN = "debian"
    ARCH = "arch"
    UNKNOWN = "unknown"


def detect() -> Distro:
    """Detect the current Linux distribution from /etc/os-release."""
    os_release = Path("/etc/os-release")
    if not os_release.exists():
        logging.warning("Cannot find /etc/os-release")
        return Distro.UNKNOWN

    text = os_release.read_text()
    id_line = ""
    id_like_line = ""
    for line in text.splitlines():
        if line.startswith("ID="):
            id_line = line.split("=", 1)[1].strip().strip('"').lower()
        elif line.startswith("ID_LIKE="):
            id_like_line = line.split("=", 1)[1].strip().strip('"').lower()

    all_ids = f"{id_line} {id_like_line}"

    if "fedora" in all_ids:
        return Distro.FEDORA
    if "debian" in all_ids or "ubuntu" in all_ids:
        return Distro.DEBIAN
    if "arch" in all_ids:
        return Distro.ARCH

    logging.warning(f"Unknown distro: ID={id_line}, ID_LIKE={id_like_line}")
    return Distro.UNKNOWN


class PackageManager(ABC):
    @abstractmethod
    def install(self, packages: list[str]) -> None: ...

    @abstractmethod
    def add_repo(self, name: str, url: str) -> None: ...

    @abstractmethod
    def is_installed(self, package: str) -> bool: ...


class DnfManager(PackageManager):
    def install(self, packages: list[str]) -> None:
        cmd.run("dnf", "install", "-y", *packages, sudo=True)

    def add_repo(self, name: str, url: str) -> None:
        cmd.run("dnf", "copr", "enable", url, "-y", sudo=True)

    def is_installed(self, package: str) -> bool:
        result = cmd.run("rpm", "-q", package, check=False, capture=True)
        return result.returncode == 0


class AptManager(PackageManager):
    def install(self, packages: list[str]) -> None:
        cmd.run("apt-get", "install", "-y", *packages, sudo=True)

    def add_repo(self, name: str, url: str) -> None:
        cmd.run("add-apt-repository", "-y", url, sudo=True)
        cmd.run("apt-get", "update", sudo=True)

    def is_installed(self, package: str) -> bool:
        result = cmd.run("dpkg", "-s", package, check=False, capture=True)
        return result.returncode == 0


class PacmanManager(PackageManager):
    def install(self, packages: list[str]) -> None:
        cmd.run("pacman", "-S", "--noconfirm", *packages, sudo=True)

    def add_repo(self, name: str, url: str) -> None:
        raise NotImplementedError("Pacman support is stubbed")

    def is_installed(self, package: str) -> bool:
        result = cmd.run("pacman", "-Qi", package, check=False, capture=True)
        return result.returncode == 0


_MANAGERS = {
    Distro.FEDORA: DnfManager,
    Distro.DEBIAN: AptManager,
    Distro.ARCH: PacmanManager,
}


def get_manager(distro: Distro) -> PackageManager:
    cls = _MANAGERS.get(distro)
    if cls is None:
        raise InstallerError(f"No package manager for distro: {distro.value}")
    return cls()
