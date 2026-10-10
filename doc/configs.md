# Configuration reference

Each subdirectory of `stow/` is a stow package. This page describes what each
one configures.

## git

Git configuration with conditional includes for switching between the personal and the work (Recombee, isee) identity by directory. Ships a global gitignore (`~/.config/git/ignore`).

The OpenPGP signing subkey held on the YubiKey (`0xE8F8EF0B655EAAB3!`, pinned with the trailing `!` so gpg cannot pick a different subkey) is configured in `core.gitconfig`, but `commit.gpgsign` and `tag.gpgsign` are **off by default** -- most commits here come from AI agent sessions, and every signature blocks on a physical YubiKey touch. Signing is opt-in per command: `git commit -S`, or the `resign` alias (`git commit --amend --no-edit -S`) to add a signature to the last commit after the fact, e.g. one an agent made unsigned; commits made through lazygit sign by default, see the `lazygit` section. `recombee.gitconfig` keeps an explicit `gpgsign = false`: the key carries UIDs only for `trojakjan24@gmail.com` and `jantrojak@ext.isee.ai`, so a Recombee-authored signature would be reported as Unverified until that UID is added to the key -- note that an explicit `-S` (`git commit -S`, `git resign`) overrides even that, so don't use it there. The agent and card setup lives in the `gnupg` package; provisioning the key itself is [yubikey.md](yubikey.md).

Files: `~/.gitconfig`, `~/.config/git/core.gitconfig`, `~/.config/git/recombee.gitconfig`, `~/.config/git/isee.gitconfig`, `~/.config/git/ignore`

## gnupg

The three GnuPG configuration files needed by the YubiKey OpenPGP applet -- the keyring, trustdb and card stubs stay out of the repo, so the package is stowed with `--no-folding` and the installer tightens `~/.gnupg` back to `0700` afterwards (stow creates it with the ambient umask, and gpg refuses to trust a world-readable home).

- `gpg.conf` -- long key IDs, subkey fingerprints, no banner
- `gpg-agent.conf` -- PIN cached for 10 minutes of activity, 2 hours hard cap; `pinentry-gnome3`, which is the pinentry that reliably takes keyboard focus under Sway
- `scdaemon.conf` -- `disable-ccid`, which forces scdaemon through PC/SC instead of its built-in CCID driver; without it the two fight over exclusive access to the card

Needs a running `pcscd` (`pcsc-lite` on Fedora, `pcscd` on Debian/Ubuntu -- both are in the installer's package list and ship their own socket activation). After changing either conf: `gpgconf --kill gpg-agent`.

Files: `~/.gnupg/gpg.conf`, `~/.gnupg/gpg-agent.conf`, `~/.gnupg/scdaemon.conf`

## zsh

Oh My Zsh with plugins: git, zsh-autosuggestions, kube-ps1, kubectl, helm,
fluxcd. The installer clones Oh My Zsh and the autosuggestions plugin
automatically.

Files: `~/.zshrc`

The command line uses vi keys (`bindkey -v`, set after oh-my-zsh because its `lib/key-bindings.zsh` runs `bindkey -e`). The prompt starts with a one-letter mode -- `I` insert (green), `N` normal (yellow), `V` visual / `L` visual line (magenta), `R` replace (red) -- and the cursor is a beam in insert/replace, a block otherwise. Visual mode is not a keymap in zsh, only `REGION_ACTIVE` inside `vicmd`, so the letter is refreshed from a `line-pre-redraw` hook as well as `keymap-select`. Insert mode keeps the emacs `Ctrl+A`/`E`/`K`/`U`/`W`, and fzf's `Ctrl+R`/`Ctrl+T`/`Ctrl+F`, `Ctrl+O` (copybuffer) and `Ctrl+X Ctrl+E` (edit in nvim) still work there.

The right-hand prompt carries a devshell indicator next to `kube_ps1`, driven by `IN_NIX_SHELL` (set by `nix develop` and by direnv's `use flake`) and `DIRENV_DIR` (set by direnv only), so it says both what is loaded and where it came from:

| Indicator | Meaning |
|---|---|
| `❄ hub` | nix devShell auto-loaded by direnv from `~/dev/zezav/hub` |
| `❄ nix` | nix devShell entered by hand (`nix develop`, no `.envrc`) |
| `● hub` | `.envrc` loaded, but not a nix shell |
| `✗ hub` | `.envrc` found above `$PWD` but not loaded — run `direnv allow` |

`zoxide` (a `home.packages` entry in `home/packages.nix`) is activated in `~/.zshrc` with `eval "$(zoxide init zsh --cmd cd)"`. It tracks the directories visited and ranks them by frecency. With `--cmd cd` the `cd` builtin itself is replaced: `cd <fragment>` jumps to the best match (an exact path still works as before), `cdi` opens the list in fzf. `z` and `zi` are kept as aliases for `cd`/`cdi`. The database lives at `~/.local/share/zoxide/db.zo` and is not part of this repo, so a fresh machine starts with an empty history.

Tab completion is registered by `zoxide init` itself (`compdef __zoxide_z_complete cd`) and it has two distinct branches, which is the usual source of confusion: `cd foo<TAB>` (no trailing space) falls through to plain *local* directory completion, while `cd foo␣<TAB>` — fragment, **space**, then Tab — is the one that queries the database and opens the fzf picker. The picker's result is delivered back over a terminal round-trip: zoxide prints a Device Status Report query (`\e[5n`) and binds the terminal's `\e[0n` reply to a ZLE helper that fills in the line. A terminal that does not answer DSR leaves the completion doing nothing at all, silently — foot and tmux both answer, so this works here.

fzf's own shell integration is loaded with `eval "$(fzf --zsh)"`, which covers Ctrl+R (history), Ctrl+T (files) and Alt+C, plus the `**<TAB>` completion trigger; `~/.zshrc` rebinds the cd widget to Ctrl+F afterwards. `fzf --zsh` is used rather than sourcing the packaged scripts because their location is distro-specific (`/usr/share/fzf/shell/` on Fedora, `/usr/share/doc/fzf/examples/` on Debian/Ubuntu) and a hardcoded path fails *silently* — the `[[ -f ]]` guard simply skips, leaving Ctrl+R on the plain zsh default and `^F` bound to a widget that does not exist.

## direnv

Auto-loads a repo's `.envrc` on `cd` (`eval "$(direnv hook zsh)"` in `~/.zshrc`); nix-direnv caches flake devShells so repeated `cd`s are instant. The `direnv` binary and the two config files are set up by the `direnv` installer step (`installer/steps/s10_direnv.py`) rather than stowed; nix-direnv itself (like `nix-zsh-completions`) is a `home.packages` entry in `home/packages.nix`, so home-manager is the only thing that writes `~/.nix-profile` — nothing is `nix profile install`ed by hand.

`direnv.toml` trims the per-`cd` log to a single dim line — the `direnv: export +CONFIG_SHELL +DETERMINISTIC_BUILD ...` wall of text a Nix devShell exports is hidden via `hide_env_diff`, and `log_filter` keeps only loading/unloading/error/warning messages, dropping nix-direnv's `using flake` and `Using cached dev shell`. Note `log_filter` is an **allow**-list, not a deny-list (the man page's "filter out" is misleading), matched against the message without the `direnv: ` prefix. Errors ignore `log_format` and stay red. Set `log_format = "-"` to silence direnv entirely — the zsh indicator above still shows what is loaded.

Files: `~/.config/direnv/direnvrc`, `~/.config/direnv/direnv.toml`

## nvim

Neovim with lazy.nvim as plugin manager. Plugins are individual files under
`lua/plugins/`. Key plugins:

- **LSP**: mason-lspconfig with an explicit allow-list of servers to enable,
  native LSP configs in `lsp/`
- **blink.cmp**: completion (LSP, path, snippets, buffer, spelling)
- **lazygit** (`lua/lazygit.lua`, no plugin): lazygit in a tab page of its own, named `lazygit: <repo>` in the tab bar -- `<leader>gg` on the cwd, `<leader>gG` on the current file's repo, `<leader>gl` for the commits touching the current buffer (`lazygit -f`). Neovim's terminal runs the binary via `jobstart()`; when lazygit exits the tab closes and the previous tab is current again, and while it runs `<leader>gg` jumps back to it instead of starting a second one. Commits made from here sign under the same rule as the `lg` shell function: the launcher asks `git-can-sign` and, if it agrees, passes `GIT_CONFIG_*` in the job's own environment. lazygit.nvim was used before and only does floating windows
- **diffview.nvim**: side-by-side diffs with a file panel -- `<leader>gd` the working tree, `<leader>gm` the branch against the merge-base with main/master (working tree included, so it is the pre-PR view; the default branch comes from `origin/HEAD`, falling back to a local `main` or `master`; `<leader>gM` picks the base branch from a Telescope list instead; `<leader>gc` lists the same branch's commits since the merge-base, to step through one at a time, and `W` in its panel opens the uncommitted -- unstaged and staged -- changes in a tab of their own), `<leader>gh` / `<leader>gH` file and branch history, `q` closes (diffview ships no close key of its own). Icons are off and the panel's `A`/`M`/`D`/`R` status letters are painted over with `+`/`~`/`_`/`>` (overlay extmarks, redone on every panel render -- diffview hardcodes the letters), so it draws the same ASCII as gitsigns, nvim-tree and delta. `gF` opens the file in a full tab, `z>`/`z<` widen or narrow the folded context
- **vim-fugitive**: `:Git` for anything, `<leader>gs` interactive status, `<leader>gb` blame as a buffer, `<leader>gv` vimdiff against the index, `<leader>gw` stage the file. `:Git commit` here does not sign -- it runs with the working tree's git config -- use lazygit for signed commits
- `<leader>g` is the git prefix shared by the three; the LSP goto maps moved to `<leader>l` to make room (`gd` still works)
- **telescope**: fuzzy finder, with fzf-native for the matching and telescope-frecency for the ranking -- `<leader>ff` lists project files with the ones you open most often and most recently on top, `<leader>fF` is the plain unranked listing, `<leader>fr` is frecency across every project. The score database lives at `~/.local/state/nvim/file_frecency.bin`
- **treesitter**: syntax highlighting, on the `main` branch (the `master` branch is frozen at Neovim 0.11 and its query directives crash the 0.12 highlighter). `main` has no `highlight.enable`/`auto_install`, so `nvim_treesitter.lua` starts highlighting and installs missing parsers from a `FileType` autocommand. Parsers live in `~/.local/share/nvim/site/parser/` and are compiled with the `tree-sitter` CLI from home-manager
- **render-markdown**: in-buffer Markdown preview (headings, code blocks, tables, callouts); `:RenderMarkdown toggle`
- **conform**: formatting (stylua, prettier, black, etc.)
- **gruvbox**: colorscheme
- **gitsigns**: `+`/`~`/`_` gutter marks and the `<leader>h` hunk family (preview inline, stage, discard, blame line, word diff); `]c`/`[c` walk hunks and fall through to Vim's own motion inside a diff window. Diff rendering itself is set in `lua/options.lua`: `algorithm:histogram` and `linematch:60` (up from the default 40) on top of Neovim 0.12's `inline:char` default, `╱` filler rows, and diffview's `enhanced_diff_hl` so removed lines are red on the left rather than green
- **nvim-tree**, **lualine**, **which-key**, **obsidian.nvim**

There is no tab bar and no session restore: `nvim` with no argument opens an
empty buffer, and `<leader>e` opens the file tree on demand. Spell checking has
two per-buffer levels -- `<leader>ss` (built-in, en+cs) and `<leader>sa` (adds
ltex-ls grammar, English only, off until asked); see
`stow/nvim/.config/nvim/README.md`.

Folding is core config rather than a plugin, and it is treesitter-driven: `foldmethod=expr` with `foldexpr=v:lua.vim.treesitter.foldexpr()`, so the fold boundaries come from the syntax tree -- a function body, a class, a JSON object, a YAML block -- and neither a multi-line call signature nor a blank line inside a block can split a fold the way indent-based folding does; a buffer whose language has no parser installed simply gets no folds (`foldexpr` returns 0) rather than an error. `foldlevelstart = 99` keeps it unobtrusive -- every file opens fully expanded and folding only happens on demand. A custom `foldtext` renders a closed fold as its own first line, syntax-highlighted, plus a dimmed count of the hidden lines. `foldcolumn` is deliberately `0` -- Vim draws a marker there only for *closed* folds and prints the fold level as a digit per column for open nested ones, so deeply indented code gets a `234` margin on every line. The marker is drawn from `statuscolumn` instead (`_G.fold_marker()` in `options.lua`), which puts a chevron only on lines that actually open a fold, down for open and right for collapsed. That `foldtext` builds its highlight chunks by running the treesitter `highlights` query over the first line: Neovim's built-in `foldtext = ""` does the same highlighting but cannot have the line count appended, and `vim.treesitter.foldtext()` was removed in 0.12 (calling it is what makes a fold render as a bare `0`, which is how Vim reports a failed foldtext expression). `<leader>z` toggles the fold under the cursor and `<leader>Z` toggles all folds; the built-in `za`/`zo`/`zc`/`zR`/`zM` keys work as usual. **indent-blankline** is the companion for blocks that are still open -- an indent guide per level with the cursor's own scope, also treesitter-derived, accented from its opening line to its closing one. **nvim-treesitter-context** covers the other direction: once the line opening the current function or class scrolls off the top, it is pinned there as a header, listing every scope around the first visible line (`mode = "topline"`, so it follows the view rather than the cursor) in every window, both diff panes included (`multiwindow`); `[x` jumps to it and `<leader>tc` toggles it.

Light or dark is **not** pinned in the config: `lua/theme.lua` reads `~/.config/foot/theme-mode.ini` -- the file `foot-theme-watcher.sh` already rewrites on every `gsettings org.gnome.desktop.interface color-scheme` change -- and sets `background` from it at startup, then keeps a `vim.uv` fs_event on the *directory* (the watcher replaces the file rather than editing it, so a watch on the inode would fire once and die) so a flip from the waybar applet repaints running instances live. This matters because gruvbox runs with `transparent_mode = true` and never paints `Normal`'s background: foot's shows through, so the two have to agree or you get light gruvbox syntax colours on a black terminal. `<leader>tb` is the manual override.

Whitespace is shown by default -- `space = ·`, `tab = → `, with deliberately different characters for the kinds that are mistakes (`trail = •`, `nbsp = ␣`) so an error never looks like ordinary indentation -- and `<leader>tw` turns it off per buffer for prose.

Python is the one language with two servers attached: `ruff` for lint diagnostics and the fix/organize-imports code actions, `basedpyright` for everything that needs to understand the code. `ruff` alone cannot answer `textDocument/definition`, `textDocument/hover` or completion, so without `basedpyright` a Python buffer reports *"method ... is not supported by any server"* on `gd`. `lsp/ruff.lua` turns ruff's hover off and `lsp/basedpyright.lua` turns basedpyright's organize-imports off, so no request has two owners. `lsp/basedpyright.lua` also filters basedpyright's diagnostics down to severity `Error` in both the push (`textDocument/publishDiagnostics`) and pull (`textDocument/diagnostic`) handlers: basedpyright defaults to `recommended`, a far stricter mode than pyright's `standard` (121 diagnostics over 84 lines of one file in the beyond repo, versus 20 at `standard`), and a project that ships `pyrightconfig.json` makes pyright ignore the client's `typeCheckingMode` outright -- so the filter has to sit on the Neovim side to be reliable. Lint stays ruff's.

Files: `~/.config/nvim/`

## sway

Sway window manager with modular configuration:

- `config` -- main config. It includes `config.d/*.conf` and `modes.d/*.conf`, plus the system layers under `/etc/sway/config.d/` and `/usr/share/sway/config.d/`. It does **not** include any `outputs` or `workspaces` file: monitor geometry and workspace-to-output pinning belong to kanshi (see below), and a second source of truth would fight it.
- `config.d/` -- variables, keymaps, inputs, appearance, custom keybindings
- `modes.d/` -- resize mode
- `wallpaper/` -- wallpaper images

Also includes configs for the full Sway ecosystem:

- **waybar** -- status bar with gammastep and colorscheme toggle scripts. The colorscheme applet is the light/dark switch for the whole desktop: it flips `org.gnome.desktop.interface color-scheme` (the single source of truth that foot, k9s, nvim, delta and VS Code follow) together with `gtk-theme` (`Adwaita-dark`/`Adwaita`) for plain GTK3 apps that only know theme names. `sway/config` sets dark as the login default with `exec`, not `exec_always`, so a `swaymsg reload` does not undo a toggle. `colorscheme.sh dark|light` sets a mode explicitly.
- **swaylock** -- lock screen config and background image
- **kanshi** -- the single owner of output layout. `stow/sway/.config/kanshi/config` defines two profiles: `docked` (Dell P3225QE matched by its `Dell Inc. DELL P3225QE 230KLJ4` descriptor at 3840x2160 and position 0,0, with `eDP-1` matched by connector name at 1920x1080 and position 974,2160 underneath it, plus an `exec swaymsg` hook pinning workspace 1 to the Dell and workspace 2 to `eDP-1`) and `laptop` (`eDP-1` alone at 0,0). kanshi matches a profile only when the profile's output set is exactly the set of connected outputs, so every connected output must be listed. It runs as the `kanshi.service` user unit from the **systemd** stow package, bound to `sway-session.target` -- not as a sway `exec` -- so it is supervised, logs to `journalctl --user -u kanshi` and restarts with the session.
- **gammastep** -- night light (geoclue-based)
- **nwg-bar** -- power menu / session management
- **swaync** -- notification center; started by `swaync.service`, which `sway-session.target` (systemd package) pulls in, so it restarts after a crash -- no `exec` line in the sway config

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

The `pre-commit` framework is deliberately **not** a mise tool -- it is a `home.packages` entry in `home/packages.nix`, so the CLI is on `PATH` in every repo regardless of whether that repo has a `mise.toml`. This repo's own hooks still run through lefthook (`lefthook.yml`, installed by `mise run install-hooks`); `pre-commit` is there for projects that define `.pre-commit-config.yaml` instead.

## systemd

User-level systemd services and environment configuration:

- **ssh-agent.service** -- persistent SSH agent
- **git-autopush-vnotes.service/.timer** -- periodic auto-commit and push for VNotes
- **openclaw-gateway.service** -- OpenClaw gateway daemon
- **plantuml-server.service** -- PlantUML picoweb on `127.0.0.1:18123` (plantuml + graphviz from `home/packages.nix`); VS Code's `jebbs.plantuml` points `plantuml.server` at it, because ```` ```plantuml ```` fences in the Markdown preview only render through a server and a loopback one keeps diagram sources off plantuml.com
- **battery-notify.service/.timer** -- polls battery capacity every 2 min and
  fires a `notify-send` low/critical warning (via swaync) while discharging;
  runs the `battery-notify` script from `my-scripts`
- **claude-rc@.service** -- template that keeps a Claude Code Remote Control server (`claude remote-control --spawn worktree`) always running, so new sessions can be started from claude.ai/code or the Claude app at any time; enabled instances `i-dot`, `p-dot`, `i-agents`, `p-hub` (see `claude-rc` in my-scripts and `doc/claude-sessions.md`). Each runs in a detached tmux session on its own socket because the server is a TUI; `Restart=always` brings it back when claude exits
- **environment.d/** -- global env vars, PATH extensions, TERM setting

Files: `~/.config/systemd/user/`, `~/.config/environment.d/`

## my-scripts

Custom scripts installed to `~/.local/bin/`. Uses `--no-folding` to avoid
replacing the shared bin directory with a symlink.

- **vn** -- VNotes manager script
- **claude-rc** -- `claude-rc <instance>` maps an instance name to a Claude config (work `~/.claude` or personal `~/.claude-personal`) and a working directory, then execs `claude remote-control` through an interactive zsh so sessions get the terminal's PATH, mise and direnv; run by `systemd/claude-rc@.service`
- **battery-notify** -- checks `/sys/class/power_supply/BAT*`, notifies once
  per low/critical threshold crossing while discharging; paired with
  `systemd/battery-notify.service` + `.timer`
- **delta-theme** -- `delta` with `--light`/`--dark` and the matching gruvbox
  syntax theme picked per invocation from `~/.config/foot/theme-mode.ini`, for
  callers that re-run the binary per diff instead of re-reading a config. Used
  by the `lazygit` package; deliberately overrides `$BAT_THEME`
- **git-can-sign** -- exits 0 when a commit in the given directory (default `.`)
  would carry a verifiable signature, i.e. when the repo's `user.email` is a UID
  on the key in `user.signingkey`. The single source of truth behind both
  lazygit signing entry points, `lg` in `~/.zshrc` and the nvim lazygit launcher
- **life** -- personal tasks (one Markdown file each in the vault's `tasks/` folder) browsed in fzf, modeled on the work `jql`; see `doc/tasks.md`
- **lql** -- runs a LogQL query through `logcli` and opens the result in lnav;
  see the `lnav` section
- **wt-inventory** -- read-only sweep of every git checkout under `--root`
  (default `.`) that classifies each worktree as removable, waiting for
  review, dirty/unpushed WIP, unknown or locked. Detects squash merges via a
  `commit-tree` + `git cherry` probe, so a squashed MR/PR does not look
  unmerged. Backs the `wt-cleanup` skill in the `claude` package, which does
  the actual removing after confirmation

Files: `~/.local/bin/vn`, `~/.local/bin/battery-notify`, `~/.local/bin/delta-theme`, `~/.local/bin/git-can-sign`, `~/.local/bin/life`, `~/.local/bin/lql`, `~/.local/bin/wt-inventory`

## syncing

Syncthing container managed via podman quadlet (systemd-native container
management).

Files: `~/.config/containers/systemd/syncthing.container`

## lazygit

Diffs are rendered by [delta](https://github.com/dandavison/delta) instead of lazygit's builtin renderer.

lazygit 0.56 replaced the old `git.paging` / `git.pagers` keys with `git.diffRenderers`, a list of `{name, type, command}` entries (`type` is one of `stdinFilter`, `extDiff`, `rawGit`); `stdinFilter` pipes the diff lazygit produced through the command and displays the result, which is the right shape for a pager. Because it is a list, the builtin renderer stays reachable -- `|` cycles renderers, `\` cycles backwards. Configs written against `git.paging` are silently ignored by current lazygit, so check the key name before copying a snippet from the internet.

The command is `delta-theme --paging=never` rather than `delta` directly: lazygit spawns the renderer once per diff, so the wrapper (`my-scripts` package) can re-read the light/dark preference every time and a theme flip needs no restart. `--paging=never` matters because lazygit does its own scrolling and delta must not spawn a pager of its own.

delta's own options live in the `[delta]` section of `~/.config/git/core.gitconfig` (delta reads git config on every run, even when it is not git's pager -- and it is not one here, plain `git diff` in the shell stays plain git). The section turns the default look into plain ASCII: `keep-plus-minus-markers` puts `+`/`-` back in front of diff lines, the box-drawing rules around file names and hunk headers are off (`*-decoration-style = none`), and the file labels are `+` added, `_` removed, `~` modified, `>` renamed. That is the same alphabet gitsigns draws in Neovim's gutter and nvim-tree shows in its git column (`renderer.icons.glyphs.git` in `lua/plugins/nvim_tree.lua`, plus `?` untracked, `U` unmerged, `!` ignored), so the three places read the same.

delta itself is **not** a Nix package here -- it comes from the distro (`git-delta` in `PACKAGES` in `installer/config.py`, all three distros), unlike lazygit which is a `home.packages` entry.

The package is `--no-folding`: lazygit writes `state.yml` (last-opened repo, panel sizes) next to `config.yml`, so `~/.config/lazygit/` has to stay a real directory.

### Commit signing

lazygit has no signing option of its own: `git.commit.signOff` is the `Signed-off-by` trailer, not GPG, and `git.overrideGpg` only controls whether the commit runs in a subprocess. It just honours git's `commit.gpgsign` / `tag.gpgsign`. Since those are off globally (see the `git` section), signing is switched on for lazygit by the `lg` shell function in `~/.zshrc`, which exports `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n` -- variables git gives the same precedence as `git -c`, and which lazygit passes down to every git child it spawns.

That precedence is also the catch: it outranks a repository's own `gpgsign = false`, including the deliberate one in `recombee.gitconfig`. So `lg` first checks that the repo's `user.email` is actually a UID on the key in `user.signingkey`, and only then turns signing on -- under `~/dev/recombee` the identity is an address the key carries no UID for, and a signature there would be reported Unverified. Running `lazygit` directly is the unsigned escape hatch. The lazygit launcher in the `nvim` package (`lua/lazygit.lua`) applies the same rule through the terminal job's environment, sharing the `git-can-sign` check rather than repeating it.

Files: `~/.config/lazygit/config.yml`

## k9s

Kubernetes CLI dashboard. Ships `config.yaml`, `aliases.yaml`, custom
`plugins/` (helm-diff, cert-manager, debug-container, etc.) and gruvbox
`skins/` with a theme-watcher script for dark/light switching.

Files: `~/.config/k9s/`

## lnav

Terminal log viewer ([lnav](https://lnav.org)), used here mainly to browse Loki logs. The binary and `logcli` come from home-manager (`lnav`, `grafana-loki` in `home/packages.nix`); `home/packages.nix` also generates `_logcli` zsh completion from `logcli --completion-script-zsh`, since the package ships none. The package adds one format, `logcli_jsonl`, for the output of `logcli query -o jsonl`: timestamp from `timestamp`, body from `line`, log level from Loki's `detected_level` label, and the line shows the `pod` label; every other label is hidden from the line but stays available to lnav's filters and SQL as `labels/<name>` (e.g. `;SELECT * FROM logcli_jsonl WHERE "labels/container" = 'api'`). No theme is set: lnav's default theme uses the terminal's ANSI palette, so it follows foot's gruvbox light/dark switch by itself.

`lql` (`my-scripts`) is the entry point: `lql '<logql>' [logcli query flags]`, e.g. `lql '{namespace="board"} |= "error"' --since=1h` or `lql '{app="api"}' --tail`. It always passes `--forward` -- lnav clamps any line whose timestamp goes backwards to the previous line's time, so logcli's default newest-first order would collapse a whole result to one instant -- and `--include-common-labels`, because logcli otherwise drops the labels shared by every stream (usually the selector's own, like `namespace`). `--limit` defaults to 5000 instead of logcli's 30.

`LOKI_ADDR` (plus `LOKI_USERNAME`/`LOKI_PASSWORD`/`LOKI_ORG_ID` if a gateway ever needs them) lives in `~/.config/loki/env`, which is deliberately not in this repo; `~/.zshrc` sources it, and `lql` falls back to it when run outside an interactive shell. A direnv `.envrc` in `~` or `~/dev/isee` would not do: direnv loads only the nearest `.envrc`, so every project with its own would drop the variable.

Files: `~/.config/lnav/formats/installed/logcli_jsonl.json`; not stowed: `~/.config/loki/env`

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

## pandoc

Vendored [pandoc-ext/diagram](https://github.com/pandoc-ext/diagram) v1.2.0 Lua filter in pandoc's user data dir, so `pandoc x.md --lua-filter diagram.lua -o x.pdf` from any directory turns ```` ```plantuml ```` (and graphviz/mermaid/...) code blocks into figures. PlantUML emits SVG, which pandoc's LaTeX path converts with `rsvg-convert`; `plantuml`, `graphviz` and `librsvg` all come from `home/packages.nix`. Stowed with `--no-folding` because `~/.local/share/pandoc/` may also hold templates added by hand. To update, replace the file with the `_extensions/diagram/diagram.lua` of a newer release tag.

Files: `~/.local/share/pandoc/filters/diagram.lua`

## vscode

VSCode user settings and keybindings. The VSCodeVim bindings mirror the nvim
scheme (leader = space: `<leader>ff/fg/fb/ft` finder/grep, `<leader>n/p/x/ml`
buffers, `gd/K` + `<leader>g[dirtD]` go-to / `<leader>p[dirt]` peek /
`<leader>rn/ca` LSP, `<leader>e/E` explorer,
`<leader>gs/gb` git, `za`/`zo`/`zc`/`zR`/`zM` folding). `keybindings.json` duplicates the navigation chords with
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
`skills/` (`dev-conventions`, `bg`, `commit`, `mr`, `wt-cleanup`) and the plugin registry (`plugins/installed_plugins.json`,
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
sessions or history. Tracked: `settings.json`, global instructions
(`CLAUDE.md`), custom `agents/` and `skills/` (`dev-conventions`, `bg`,
`commit`, `mr`, `wt-cleanup`) -- the personal instance's own copies, edited
here independently of the `claude` package. Stowed with `--no-folding` because
the rest of `~/.claude-personal/` is runtime state (`skills/synced/`, the
skills synced from claude.ai, included).

Plugins are shared through `settings.json` instead: `enabledPlugins` and
`extraKnownMarketplaces` are kept identical to the work `settings.json`, and
each instance installs its own copy under its own `plugins/cache/`. They
cannot be symlinked -- Claude Code rewrites `plugins/*.json` per config dir
(replacing the file, which breaks a symlink, and it would write personal
install paths into the work registry).

Its statusline points at a private ccstatusline config
(`--config ~/.config/ccstatusline/personal.json`), which is the only way to
give the two instances different widgets -- see the `ccstatusline` section.

Files: `~/.claude-personal/settings.json`, `~/.claude-personal/CLAUDE.md`,
`~/.claude-personal/agents/`, `~/.claude-personal/skills/`

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
`home/packages.nix` installs side by side:

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

Adding a third profile is one more `mkClaudeDesktop { ... }` call in `home/packages.nix`
with a fresh `profile`/`userDataDir`.

## Cross-package dependencies

Some configs reference tools from other packages:

- **sway** references `foot` (default terminal), `rofi` (launcher), waybar
  scripts, `swaylock`, `gammastep`, `nwg-bar`
- **systemd** starts `kanshi` (`kanshi.service`, bound to `sway-session.target`); `sway-session.target` also pulls in the packaged `swaync.service`
  from the config shipped by the **sway** package at `~/.config/kanshi/config`
- **systemd** timers reference the `vn` and `battery-notify` scripts from
  `my-scripts`
- **nvim** obsidian plugin expects the notes vault at `~/ops/vnotes`
- **git** commit signing depends on the agent and card configuration in **gnupg**
