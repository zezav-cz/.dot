# Configuration reference

Each subdirectory of `stow/` is a stow package. This page describes what each
one configures.

## git

Git configuration with conditional includes for switching between personal and
work (Recombee) email/signing settings. Ships a global gitignore
(`~/.config/git/ignore`).

Files: `~/.gitconfig`, `~/.config/git/core.gitconfig`,
`~/.config/git/recombee.gitconfig`, `~/.config/git/ignore`

## zsh

Oh My Zsh with plugins: git, zsh-autosuggestions, kube-ps1, kubectl, helm,
fluxcd. The installer clones Oh My Zsh and the autosuggestions plugin
automatically.

Files: `~/.zshrc`

## nvim

Neovim with lazy.nvim as plugin manager. Plugins are individual files under
`lua/plugins/`. Key plugins:

- **LSP**: mason-lspconfig for server management, native LSP configs in `lsp/`
- **telescope**: fuzzy finder with custom tab picker
- **treesitter**: syntax highlighting and text objects
- **conform**: formatting (stylua, prettier, black, etc.)
- **nvim-lint**: linting
- **gruvbox**: colorscheme with dark-notify for automatic dark/light switching
- **gitsigns**, **nvim-tree**, **lualine**, **obsidian.nvim**

Files: `~/.config/nvim/`

## sway

Sway window manager with modular configuration:

- `config` -- main config, sources `config.d/`, `modes.d/`, `outputs`, `workspaces`
- `config.d/` -- variables, keymaps, inputs, appearance, custom keybindings
- `modes.d/` -- resize mode
- `wallpaper/` -- wallpaper images

Also includes configs for the full Sway ecosystem:

- **waybar** -- status bar with gammastep and colorscheme toggle scripts
- **swaylock** -- lock screen config and background image
- **kanshi** -- automatic display profile switching
- **gammastep** -- night light (geoclue-based)
- **nwg-bar** -- power menu / session management
- **swaync** -- notification center (config managed separately)

Files: `~/.config/sway/`, `~/.config/waybar/`, `~/.config/swaylock/`,
`~/.config/kanshi/`, `~/.config/gammastep/`, `~/.config/nwg-bar/`

## tmux

Tmux configuration: `C-a` prefix, vim-style pane navigation, mouse support.

Files: `~/.tmux.conf`

## rofi

Rofi application launcher with gruvbox dark theme.

Files: `~/.config/rofi/config.rasi`

## foot

Foot terminal emulator with gruvbox themes and a `foot-theme-watcher.sh`
script for automatic dark/light theme switching.

Files: `~/.config/foot/foot.ini`, `~/.config/foot/foot-theme-watcher.sh`

## mise

Mise (formerly rtx) version manager. Manages runtimes and CLI tools: node,
python, ruby, go, kubectl, helm, and more.

Files: `~/.config/mise/config.toml`

## systemd

User-level systemd services and environment configuration:

- **ssh-agent.service** -- persistent SSH agent
- **git-autopush-vnotes.service/.timer** -- periodic auto-commit and push for VNotes
- **openclaw-gateway.service** -- OpenClaw gateway daemon
- **environment.d/** -- global env vars, PATH extensions, TERM setting

Files: `~/.config/systemd/user/`, `~/.config/environment.d/`

## my-scripts

Custom scripts installed to `~/.local/bin/`. Uses `--no-folding` to avoid
replacing the shared bin directory with a symlink.

- **vn** -- VNotes manager script

Files: `~/.local/bin/vn`

## syncing

Syncthing container managed via podman quadlet (systemd-native container
management).

Files: `~/.config/containers/systemd/syncthing.container`

## k9s

Kubernetes CLI dashboard. Ships `config.yaml`, `aliases.yaml`, custom
`plugins/` (helm-diff, cert-manager, debug-container, etc.) and gruvbox
`skins/` with a theme-watcher script for dark/light switching.

Files: `~/.config/k9s/`

## ssh-agent

Declarative key list (`keys.conf`) consumed by the `ssh-agent-load-keys`
script from `my-scripts`; paired with `systemd/ssh-agent.service`. Keys are
loaded with `ssh-add -c` (confirm-on-use).

Files: `~/.config/ssh-agent/keys.conf`

## nwg-displays

GUI display-layout tool for Sway. Stores global settings and user-saved
monitor profiles.

Files: `~/.config/nwg-displays/config`, `~/.config/nwg-displays/profiles/`

## pgcli

Postgres REPL config. Stowed with `--no-folding` so pgcli's runtime
`history` and `log` stay local to `~/.config/pgcli/` instead of landing in
the repo.

Files: `~/.config/pgcli/config`

## Cross-package dependencies

Some configs reference tools from other packages:

- **sway** references `foot` (default terminal), `rofi` (launcher), waybar
  scripts, `swaylock`, `kanshi`, `gammastep`, `nwg-bar`
- **systemd** timer references the `vn` script from `my-scripts`
- **nvim** obsidian plugin expects the VNotes directory at `~/VNotes`
- **foot** theme watcher may interact with sway/dark-notify color scheme
  switching
