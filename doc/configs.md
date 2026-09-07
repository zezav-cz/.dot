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

- **LSP**: mason-lspconfig with an explicit allow-list of servers to enable,
  native LSP configs in `lsp/`
- **blink.cmp**: completion (LSP, path, snippets, buffer, spelling)
- **telescope**: fuzzy finder
- **treesitter**: syntax highlighting and text objects
- **conform**: formatting (stylua, prettier, black, etc.)
- **gruvbox**: colorscheme
- **gitsigns**, **nvim-tree**, **lualine**, **which-key**, **obsidian.nvim**

There is no tab bar and no session restore: `nvim` with no argument opens an
empty buffer, and `<leader>e` opens the file tree on demand. Spell checking has
two per-buffer levels -- `<leader>ss` (built-in, en+cs) and `<leader>sa` (adds
ltex-ls grammar, English only, off until asked); see
`stow/nvim/.config/nvim/README.md`.

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
Session persistence via `tpm` + `tmux-resurrect`, manual only (no autosave/
auto-restore):

- `prefix + Ctrl-s` -- save current session state as a new, unnamed timestamped
  snapshot under `~/.local/share/tmux/resurrect/`
- `prefix + N` -- save, prompting for a name first (embedded in the filename
  as `tmux_resurrect_<timestamp>__<name>.txt`;
  `stow/my-scripts/.local/bin/tmux-resurrect-save-named`)
- `prefix + F` -- fzf-pick a saved snapshot (shown as timestamp + name, newest
  first) and restore it (`stow/my-scripts/.local/bin/tmux-resurrect-load`,
  opened as a tmux popup)

Both scripts prepend `~/.local/share/mise/shims` to `PATH`, since
`display-popup`/`run-shell` don't source `.zshrc`'s `mise activate` -- needed
if `fzf` (or any other tool these scripts shell out to) is mise-managed rather
than a system package.

`tpm` itself is cloned by the `stow` installer step to `~/.tmux/plugins/tpm`
(not part of the stow package); `prefix + I` inside tmux installs/updates the
declared plugins (`@plugin` lines in `.tmux.conf`).

Files: `~/.tmux.conf`

## rofi

Rofi application launcher with gruvbox dark theme.

Files: `~/.config/rofi/config.rasi`

## foot

Foot terminal emulator with gruvbox themes and a `foot-theme-watcher.sh`
script for automatic dark/light theme switching. The watcher applies the
current `org.gnome.desktop.interface color-scheme` on start, signals running
foot instances (`SIGUSR1`/`SIGUSR2`) on every gsettings change, and writes
the matching `initial-color-theme` into `theme-mode.ini` (included from
`foot.ini`) so newly-launched foot windows also start themed correctly
instead of defaulting to dark. Paired with `systemd/foot-theme.service`.
Stowed with `--no-folding` so `theme-mode.ini` -- rewritten at runtime --
stays local to `~/.config/foot/` instead of landing in the repo.

Files: `~/.config/foot/foot.ini`, `~/.config/foot/foot-theme-watcher.sh`,
`~/.config/foot/theme-mode.ini`

## mise

Mise (formerly rtx) version manager. Manages runtimes and CLI tools: node,
python, ruby, go, kubectl, helm, and more.

Files: `~/.config/mise/config.toml`

## systemd

User-level systemd services and environment configuration:

- **ssh-agent.service** -- persistent SSH agent
- **git-autopush-vnotes.service/.timer** -- periodic auto-commit and push for VNotes
- **openclaw-gateway.service** -- OpenClaw gateway daemon
- **battery-notify.service/.timer** -- polls battery capacity every 2 min and
  fires a `notify-send` low/critical warning (via swaync) while discharging;
  runs the `battery-notify` script from `my-scripts`
- **environment.d/** -- global env vars, PATH extensions, TERM setting

Files: `~/.config/systemd/user/`, `~/.config/environment.d/`

## my-scripts

Custom scripts installed to `~/.local/bin/`. Uses `--no-folding` to avoid
replacing the shared bin directory with a symlink.

- **vn** -- VNotes manager script
- **battery-notify** -- checks `/sys/class/power_supply/BAT*`, notifies once
  per low/critical threshold crossing while discharging; paired with
  `systemd/battery-notify.service` + `.timer`

Files: `~/.local/bin/vn`, `~/.local/bin/battery-notify`

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

## vscode

VSCode user settings and keybindings. The VSCodeVim bindings mirror the nvim
scheme (leader = space: `<leader>ff/fg/fb/ft` finder/grep, `<leader>n/p/x/ml`
buffers, `gd/K` + `<leader>g[dirtD]` go-to / `<leader>p[dirt]` peek /
`<leader>rn/ca` LSP, `<leader>e/E` explorer,
`<leader>gs/gb` git). `keybindings.json` duplicates the navigation chords with
`when` guards so they also work outside a text editor (empty workbench,
sidebar trees). Stowed with `--no-folding` so VSCode's runtime state
(`workspaceStorage/`, `globalStorage/`, ...) stays out of the repo.

Files: `~/.config/Code/User/settings.json`, `~/.config/Code/User/keybindings.json`

## claude

Claude Code user-level configuration, used by the `iclaude` alias (the bare
`claude` command is disabled in `stow/zsh/.zshrc` to avoid picking the wrong
instance by accident -- see the `claude-personal` section). Only a curated
subset of `~/.claude/` is tracked -- global instructions (`CLAUDE.md`), `settings.json` (model,
hooks, statusline, enabled plugins, marketplaces), custom `agents/`,
`skills/` and the plugin registry (`plugins/installed_plugins.json`,
`plugins/known_marketplaces.json`). Stowed with `--no-folding` so runtime
state (`projects/`, `history.jsonl`, `.credentials.json`, caches, ...) stays
local to `~/.claude/` and out of the repo.

Files: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/agents/`,
`~/.claude/skills/`, `~/.claude/plugins/installed_plugins.json`,
`~/.claude/plugins/known_marketplaces.json`

## claude-personal

Settings for the second Claude Code instance, launched by the `pclaude` alias
(`stow/zsh/.zshrc`) as
`CLAUDE_CONFIG_DIR="$HOME/.claude-personal" command claude` --
a fully separate config dir, so personal and work accounts never share auth,
sessions or history. Only `settings.json` is tracked; stowed with
`--no-folding` because the rest of `~/.claude-personal/` is runtime state.

Both instances offer the same assistant setup:

- `CLAUDE.md`, `agents/` and `skills/` are symlinks into `~/.claude/`, created
  by the stow step from `CLAUDE_SHARED_LINKS` (`installer/config.py`) -- one
  source of truth, edited in the `claude` package.
- Plugins are shared through `settings.json` instead: `enabledPlugins` and
  `extraKnownMarketplaces` are kept identical to the work `settings.json`, and
  each instance installs its own copy under its own `plugins/cache/`. They
  cannot be symlinked -- Claude Code rewrites `plugins/*.json` per config dir
  (replacing the file, which breaks a symlink, and it would write personal
  install paths into the work registry).

Its statusline points at a private ccstatusline config
(`--config ~/.config/ccstatusline/personal.json`), which is the only way to
give the two instances different widgets -- see the `ccstatusline` section.

Files: `~/.claude-personal/settings.json`

## ccstatusline

Statusline renderer for Claude Code ([ccstatusline]). Wired up in the `claude`
package's `settings.json` (`statusLine.command` plus two hooks that refresh it
on `UserPromptSubmit` and `Skill` use); this package tracks the widget layout
itself. Three lines:

```
Model: Sonnet 5 | Ctx Used: 11.0% | ⎇ main | (+1,-0)
Session: 100.0% | Reset: 3hr 11m | Weekly: 25.0% | Weekly Reset: 11hr 21m
Skill: none
```

Edit interactively with `ccstatusline` (TUI) -- it writes straight through the
symlink into the repo. The binary itself comes from home-manager
(`nix/ccstatusline.nix`, pinned), so `settings.json` calls it by name rather
than through `npx -y ccstatusline@latest`, which would refetch the package on
every render.

### Two instances (`iclaude` / `pclaude`)

ccstatusline splits its state in two, and each half is scoped differently:

- **Which data it reads** (account e-mail, `session-usage`, `weekly-usage`,
  `reset-timer`) follows `CLAUDE_CONFIG_DIR`, which the `pclaude` alias already
  exports; the statusline command inherits it. Nothing to configure -- each
  instance reports its own account. The usage API response is cached in a
  single shared `~/.cache/ccstatusline/usage.json`, but it carries a hash of
  the OAuth token it was fetched with, so the other instance never displays it
  -- it just refetches (the only cost of sharing the cache file).
- **Which widgets it draws** is read from a hardcoded
  `~/.config/ccstatusline/settings.json`. It ignores `CLAUDE_CONFIG_DIR` and
  `XDG_CONFIG_HOME`; the only override is the `--config <path>` flag (parsed
  before `--hook`, so hooks take it too).

Hence `personal.json`: the `claude-personal` package's `settings.json` invokes
`ccstatusline --config ~/.config/ccstatusline/personal.json` for both the
statusline and its hooks. Edit it with the `pccstatusline` alias, which sets
`CLAUDE_CONFIG_DIR` as well so the TUI writes install changes into
`~/.claude-personal/settings.json` instead of the work one.

Files: `~/.config/ccstatusline/settings.json` (work, used by `iclaude`),
`~/.config/ccstatusline/personal.json` (used by `pclaude`)

[ccstatusline]: https://github.com/sirmalloc/ccstatusline

## Claude Code MCP servers

Not a stow package -- MCP servers (sequential-thinking, vnotes filesystem,
kubernetes) are declared in `installer/config.py` (`MCP_SERVERS`) and merged
into `~/.claude.json` by the `mcp` installer step (`s08_mcp.py`). Existing
entries are never overwritten, so manual tweaks survive re-runs. Servers are
launched via `npx` (node comes from the mise config).

## Claude Desktop (personal / work)

Not a stow package -- Claude Desktop comes from home-manager. The base
derivation (`nix/claude-desktop.nix`) repackages Anthropic's .deb;
`nix/claude-desktop-profile.nix` wraps it into two independent instances that
`home.nix` installs side by side:

| Profile | Binary | Launcher entry | Data directory |
|---|---|---|---|
| personal | `claude-desktop-personal` | Claude (Personal) | `~/.config/Claude-personal` |
| work | `claude-desktop-work` | Claude (Work) | `~/.config/Claude-work` |

The split is driven by `CLAUDE_USER_DATA_DIR`, which the app honours for its
whole Electron userData tree: session cookies and tokens, Local Storage /
IndexedDB, `claude_desktop_config.json` (MCP servers) and `Logs`. Electron's
single-instance lock lives in that tree too, so both can run at the same time
instead of the second launch focusing the first one's window.

The wrapper also sets, per profile:

- `--class` -- distinct Wayland app_id / X11 WM_CLASS
  (`com.anthropic.Claude.personal` / `.work`), so sway rules and the taskbar
  can tell the two apart. Matched by `StartupWMClass` in each `.desktop`.
- `CHROME_DESKTOP` -- the desktop-file name Electron hands to `xdg-settings`
  when it claims the `claude://` scheme. Only one instance can own the scheme,
  so it ends up being whichever was launched most recently -- which is what an
  OAuth callback needs.

The unwrapped `claude-desktop` package is deliberately not in `home.packages`:
it would add a third, unlabelled launcher entry still writing to
`~/.config/Claude`.

Adding a third profile is one more `mkClaudeDesktop { ... }` call in `home.nix`
with a fresh `profile`/`userDataDir`.

## Cross-package dependencies

Some configs reference tools from other packages:

- **sway** references `foot` (default terminal), `rofi` (launcher), waybar
  scripts, `swaylock`, `kanshi`, `gammastep`, `nwg-bar`
- **systemd** timers reference the `vn` and `battery-notify` scripts from
  `my-scripts`
- **nvim** obsidian plugin expects the notes vault at `~/ops/vnotes`
