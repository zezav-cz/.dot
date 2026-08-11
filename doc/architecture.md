# Architecture

## GNU Stow layout

All stow packages live under `stow/`. Each subdirectory of `stow/` is a stow
package whose internal structure mirrors `~/`, so
`stow -d stow -t ~ nvim` (run from the repo root) creates symlinks like:

```
stow/nvim/.config/nvim/init.lua  -->  ~/.config/nvim/init.lua
stow/sway/.config/sway/config    -->  ~/.config/sway/config
stow/my-scripts/.local/bin/vn    -->  ~/.local/bin/vn
```

By default, Stow creates symlinks at the highest possible directory level
("folding"). For packages like `my-scripts` where you do not want
`~/.local/bin/` itself to become a symlink, `--no-folding` is used instead.
Packages using each mode are listed in `installer/config.py`:

- `STOW_PACKAGES` -- normal folding
- `STOW_NO_FOLDING` -- `--no-folding` flag

## Installer pipeline

```
install.py  (CLI, argument parsing, step dispatch)
  |
  +-- installer/steps/     (9 ordered step modules)
  +-- installer/config.py  (all data: package lists, URLs, stow targets)
  +-- installer/cmd.py     (subprocess wrapper with dry-run, download, retries)
  +-- installer/distro.py  (distro detection + PackageManager abstraction)
  +-- installer/log.py     (logging setup)
```

`install.py` iterates over the ordered step list and calls each module's
`run_step(dry_run)` function. Steps can be selected or skipped via `--only` and
`--skip`.

## The 9 installation steps

| # | Name       | Module             | What it does |
|---|------------|--------------------|--------------|
| 1 | `update`   | `s00_update.py`    | Update all system packages (`dnf update -y`) before installing anything. Fedora only. |
| 2 | `repos`    | `s01_repos.py`     | Enable COPR repos (mise, nwg-shell, cliphist, nerd-fonts, prismlauncher) and add the VS Code yum repo. |
| 3 | `packages` | `s02_packages.py`  | Install all system packages via dnf (dev tools, Sway utilities, build deps, Cockpit, etc.). |
| 4 | `shell`    | `s03_shell.py`     | Install Oh My Zsh and clone Zsh plugins (zsh-autosuggestions). |
| 5 | `apps`     | `s04_apps.py`      | Install AppImage apps declared in `APPS` (`installer/config.py`): download, optional GPG verification against the vendor key, install to `~/.local/bin/<name>`, download icon, write `.desktop` entry to `~/.local/share/applications/`. Currently Obsidian and Signal. Adding an app = adding one `AppInstall` entry to `APPS`. Zotero support is stubbed out. |
| 6 | `fonts`    | `s05_fonts.py`     | Download Nerd Fonts (Meslo) and Font Awesome, update font cache. |
| 7 | `stow`     | `s06_stow.py`      | Symlink all packages under `stow/` into `~/` using `stow -d stow -t $HOME`. Removes a plain `~/.zshrc` first if present. |
| 8 | `vnotes`   | `s07_vnotes.py`    | Clone or pull the private VNotes repository to `~/VNotes`. |
| 9 | `mcp`      | `s08_mcp.py`       | Register Claude Code MCP servers from `MCP_SERVERS` (`installer/config.py`) by merging missing entries into `~/.claude.json`. Never overwrites existing entries. |

## Dependency graph

Steps run in order because later steps depend on earlier ones:

```
update --> repos --> packages --> shell --> apps --> fonts --> stow --> vnotes --> mcp
```

- `packages` needs repos enabled first
- `shell` needs `zsh` from packages
- `stow` needs `stow` binary from packages and configs to exist
- `vnotes` needs `git` from packages
- `mcp` runs after `vnotes` because the vnotes MCP server points at the
  cloned `~/vnotes` directory (servers run via `npx`, provided by mise/node)

## Distro abstraction layer

`installer/distro.py` provides multi-distro support:

- **Detection**: reads `/etc/os-release`, matches `ID` and `ID_LIKE` fields
  against known distros (Fedora, Debian/Ubuntu, Arch).
- **`Distro` enum**: `FEDORA`, `DEBIAN`, `ARCH`, `UNKNOWN`.
- **`PackageManager` ABC**: defines `install()`, `add_repo()`,
  `is_installed()`. Concrete implementations:
  - `DnfManager` -- Fedora (dnf/rpm)
  - `AptManager` -- Debian/Ubuntu (apt-get/dpkg)
  - `PacmanManager` -- Arch (pacman)
- **`get_manager(distro)`**: factory returning the right manager instance.

## cmd.py utilities

The `installer/cmd.py` module wraps all subprocess calls:

- `run()` -- execute a command with optional `sudo`, `check`, `capture`,
  `input`. Respects the global `DRY_RUN` flag.
- `download()` -- wget with retries.
- `is_installed()` -- check if a binary is on PATH.
- `ensure_dir()` -- `mkdir -p` with dry-run awareness.
- `package_installed()` -- distro-aware package query.
