# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal dotfiles repo for bootstrapping a fresh Fedora Sway Spin laptop. Configs are managed with **GNU Stow** -- all packages live under `stow/`, one subdirectory per package, whose contents mirror `~/`.

See `doc/` for deeper documentation: `architecture.md` (installer internals), `configs.md` (per-package overview), `adding-a-package.md`, `distro-support.md`.

## Installation (end-user)

```bash
# Full setup on a fresh system
python3 install.py

# Common flags
python3 install.py --list                   # show available steps
python3 install.py --only stow              # run just the stow step
python3 install.py --skip repos packages    # skip heavy steps
python3 install.py --dry-run                # preview without executing
python3 install.py -v                       # verbose
```

The installer (`install.py` + `installer/`) runs 7 ordered steps: `repos -> packages -> shell -> apps -> fonts -> stow -> vnotes`. Each step is a module in `installer/steps/sNN_*.py` exposing `run_step(dry_run)`.

## Dev tooling (when editing this repo)

```bash
mise install       # install all tools (lefthook, uv, ruff, editorconfig-checker)
mise run setup     # uv sync + lefthook install in one step
```

Tools are managed by `mise.toml` (all versions pinned). The dev Python environment is managed by `uv` (`pyproject.toml` + `uv.lock`); `uv sync` creates `.venv` with `ruff`.

### Available mise tasks

| Task | What it does |
|---|---|
| `mise run lint` | `ruff check` on Python sources |
| `mise run lint:fix` | ruff lint with safe auto-fixes |
| `mise run format` | `ruff format` (applies formatting) |
| `mise run format:check` | formatting check without modifying files |
| `mise run check` | lint + format:check (run both) |
| `mise run sync` | `uv sync` — refresh the dev venv |
| `mise run install-hooks` | install lefthook git hooks |
| `mise run setup` | sync + install-hooks |

### Git hooks (lefthook.yml)

- **pre-commit** (parallel): `editorconfig-checker` on all staged files; `ruff check` + `ruff format --check` on staged `.py` files.
- **pre-push**: `mise run check` (full lint + format check, non-incremental).

Edits must conform to `.editorconfig` (2-space indent, UTF-8, LF, trailing-whitespace trimmed). Python formatting follows ruff defaults (line length 88, double quotes, LF line endings).

## Architecture notes

- **`installer/config.py` is the single source of truth** for all installer data: COPR repos, package lists per distro, font downloads, AppImage versions/URLs, Oh-My-Zsh plugins, `STOW_PACKAGES`, `STOW_NO_FOLDING`, VNotes repo. Prefer changing data there over editing step modules.
- **Distro abstraction**: `installer/distro.py` detects the distro from `/etc/os-release` and provides a `PackageManager` ABC with `DnfManager`, `AptManager`, `PacmanManager`. Fedora is fully supported; Debian/Arch package lists are partial stubs.
- **Subprocess wrapper**: all shell-outs go through `installer/cmd.py` (`run`, `download`, `is_installed`, `ensure_dir`, `package_installed`) which respects the global `DRY_RUN` flag. Do not call `subprocess` directly from steps.

## Stow package layout

Each stow package lives under `stow/` and mirrors the home directory structure:

```
stow/nvim/.config/nvim/      ->  ~/.config/nvim/
stow/sway/.config/sway/      ->  ~/.config/sway/
stow/my-scripts/.local/bin/  ->  ~/.local/bin/
```

The installer runs `stow -d stow -t $HOME <pkg>` from the repo root. Registered packages: `git`, `mise`, `nvim`, `rofi`, `ssh-agent`, `sway`, `systemd`, `tmux`, `zsh`, `foot`, `k9s`, `nwg-displays`. `my-scripts` and `pgcli` are listed in `STOW_NO_FOLDING` (uses `stow --no-folding`) so the shared target directory does not itself become a symlink.

When adding a new config, create its stow-compatible directory structure under a new subdirectory of `stow/`, then add it to `STOW_PACKAGES` or `STOW_NO_FOLDING` in `installer/config.py`.

## Config-specific notes

- **Neovim**: Lua, lazy.nvim plugin manager. One plugin per file under `stow/nvim/.config/nvim/lua/plugins/`. LSP server configs live in `stow/nvim/.config/nvim/lsp/`.
- **Sway**: split across `config`, `config.d/`, `modes.d/`, `outputs`, `workspaces`.
- **Installer code (Python)**: dataclasses + pathlib; distro-specific logic must go through `installer/distro.py`.
