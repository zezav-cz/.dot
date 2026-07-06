# Distro support

## Current status

| Distro        | Status | Package manager | Notes |
|---------------|--------|-----------------|-------|
| Fedora        | Full   | dnf / rpm       | Primary target. COPR repos, VS Code and Warp repos, full package list. |
| Debian/Ubuntu | Stub   | apt-get / dpkg  | Manager implemented, package lists not yet ported. |
| Arch          | Stub   | pacman           | Manager implemented, repo management not wired up. |

## What is portable

**Portable** (works on any distro):
- All stow package configs (sway, nvim, zsh, git, tmux, foot, rofi, etc.)
- The stow linking step itself
- Oh My Zsh and plugin installation
- VNotes clone
- Font downloads

**Distro-specific**:
- Repository setup (COPR is Fedora-only)
- System package installation (package names differ across distros)
- Package availability checks

## How detection works

`installer/distro.py` reads `/etc/os-release` and checks the `ID` and
`ID_LIKE` fields:

- `fedora` in either field --> `Distro.FEDORA`
- `debian` or `ubuntu` --> `Distro.DEBIAN`
- `arch` --> `Distro.ARCH`
- Otherwise --> `Distro.UNKNOWN` (installer will error on package steps)

## Adding support for a new distro

1. **Add to the `Distro` enum** in `installer/distro.py`.
2. **Create a `PackageManager` subclass** implementing `install()`,
  `add_repo()`, and `is_installed()`.
3. **Register it** in the `_MANAGERS` dict and update `detect()` to match the
  new distro's `ID`/`ID_LIKE` values.
4. **Add a package mapping** in `installer/config.py`. Package names often
  differ between distros (e.g., `neovim` vs `nvim`, `ruby-devel` vs
  `ruby-dev`). You will need a per-distro mapping or conditional logic.

Example -- adding openSUSE:

```python
# In installer/distro.py

class Distro(Enum):
  ...
  OPENSUSE = "opensuse"

class ZypperManager(PackageManager):
  def install(self, packages: list[str]) -> None:
    cmd.run("zypper", "install", "-y", *packages, sudo=True)

  def add_repo(self, name: str, url: str) -> None:
    cmd.run("zypper", "addrepo", url, name, sudo=True)

  def is_installed(self, package: str) -> bool:
    result = cmd.run("rpm", "-q", package, check=False, capture=True)
    return result.returncode == 0
```
