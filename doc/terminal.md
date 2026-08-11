# Terminal Reference

Quick reference for everything available in the shell — aliases, keybindings, plugins, and tools.

---

## Aliases

### Editors / openers

| Alias | Expands to | Notes |
|---|---|---|
| `vim` | `nvim` | Always points to Neovim |
| `vvim` | `command vim` | Bypass the alias, open real Vim |
| `vs` | `code .` | Open current directory in VS Code |
| `lg` | `lazygit` | Full TUI git client |
| `x <path>` | `xdg-open <path>` | Open file/URL with default app |

### Shortcuts

| Alias | Expands to |
|---|---|
| `g` | `git ` |
| `t` | `tmux ` |
| `k` | `kubectl ` |
| `py` | `python3 -q ` |
| `copy` | `wl-copy` |
| `rclaude` | `claude` with a separate config dir for Recombee (`~/.claude-recombee`) |

### Git aliases (from `~/.config/git/core.gitconfig`)

| Alias | Expands to |
|---|---|
| `g st` | `git status` |
| `g ci` | `git commit` |
| `g co` | `git checkout` |
| `g br` | `git branch` |
| `g ll` | `git log --oneline --graph --all --decorate` |
| `g wf` | Set remote origin to fetch all branches |
| `g pushf` | `git push --force-with-lease` |

---

## Zsh plugins (Oh My Zsh)

### `git`
Adds ~60 git aliases. Most useful ones:

| Alias | Command |
|---|---|
| `gst` | `git status` |
| `ga` | `git add` |
| `gcmsg` | `git commit -m` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `gp` | `git push` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gbd` | `git branch -d` |
| `grb` | `git rebase` |
| `gsta` | `git stash push` |
| `gstp` | `git stash pop` |
| `glog` | `git log --oneline --decorate --graph` |

Full list: `alias | grep "='git"`

### `zsh-autosuggestions`
Suggests commands as you type based on history. Press `→` (right arrow) or `End` to accept the full suggestion. Press `Ctrl+→` to accept the next word only.

### `zsh-syntax-highlighting`
Colors commands as you type — green for valid commands, red for unknown ones.

### `copybuffer` (`Ctrl+O`)
Copies the current command line content to the clipboard (Wayland: `wl-copy`). Useful for pasting a long command into another app without running it.

### `copyfile`
`copyfile <file>` — copies the contents of a file to the clipboard.

### `kube-ps1`
Shows the current Kubernetes context and namespace in the right prompt: `(context|namespace)`. The prompt updates automatically when you switch contexts with `kubectx`.

### `kubectl`
Tab completion for `kubectl` (and the `k` alias). Also adds `kj` / `ky` aliases for JSON/YAML output.

### `helm` / `fluxcd`
Tab completion for `helm` and `flux` commands.

---

## Shell history

| Setting | Effect |
|---|---|
| `HISTSIZE` / `SAVEHIST` = 50 000 | Keeps 50k commands in memory and on disk (`~/.zsh_history`) |
| `HIST_IGNORE_ALL_DUPS` | Duplicate commands are collapsed — only the latest occurrence is kept |
| `HIST_FIND_NO_DUPS` | `Ctrl+R` skips duplicates while browsing |
| `HIST_IGNORE_SPACE` | Prefix any command with a space to exclude it from history entirely |

## fzf

Fuzzy finder integrated into the shell via `/usr/share/fzf/shell/key-bindings.zsh`.

| Keybinding | Action |
|---|---|
| `Ctrl+R` | Fuzzy search shell history — type to filter, Enter to run |
| `Ctrl+T` | Fuzzy file search — inserts the selected path at the cursor |
| `Ctrl+F` | Fuzzy directory search — `cd` into the selected directory |
| `Ctrl+X E` | Open current command line in nvim for editing, paste result back |

**Inside the fzf picker:**

| Key | Action |
|---|---|
| `↑` / `↓` or `Ctrl+P` / `Ctrl+N` | Move through results |
| `Enter` | Accept selection |
| `Esc` or `Ctrl+C` | Cancel |
| `Tab` | Mark multiple items (where supported) |

---

## tmux

Prefix is `Ctrl+A` (remapped from the default `Ctrl+B`).

### Sessions / windows / panes

| Keybinding | Action |
|---|---|
| `Prefix + c` | New window |
| `Prefix + ,` | Rename window |
| `Prefix + n` / `p` | Next / previous window |
| `Prefix + <number>` | Jump to window by number (1-indexed) |
| `Prefix + "` | Split pane horizontally |
| `Prefix + %` | Split pane vertically |
| `Prefix + h/j/k/l` | Move between panes (vim keys) |
| `Prefix + x` | Kill current pane |
| `Prefix + z` | Zoom/unzoom current pane |
| `Prefix + r` | Reload tmux config |
| Mouse | Click to focus pane, drag border to resize |

### Copy mode

| Keybinding | Action |
|---|---|
| `Prefix + [` | Enter copy mode (scroll with arrow keys or vim keys) |
| `Space` | Start selection |
| `Enter` | Copy selection |
| `q` | Exit copy mode |

### From the shell

```bash
t new -s <name>      # new session named <name>
t ls                 # list sessions
t a -t <name>        # attach to session
t kill-session -t <name>
```

---

## mise

Version manager for dev tools (replaces nvm, rbenv, pyenv, etc.).

```bash
mise ls              # list installed tools
mise use <tool>@<version>   # set version for current project
mise install         # install all tools from mise.toml
mise run <task>      # run a defined task
```

---

## kubectl / k9s

`k` is aliased to `kubectl`. Tab completion is active.

```bash
k get pods -A        # all pods across namespaces
k get pods -n <ns>
k logs <pod> -f
k exec -it <pod> -- bash
```

`k9s` opens the interactive cluster dashboard. Press `?` inside k9s for help.

```bash
kubectx              # list / switch cluster contexts
kubens               # list / switch namespaces
```

---

## vn (zettelkasten notes)

Personal note-taking tool backed by `~/vnotes`.

```bash
vn create "note title"    # new inbox note
vn daily                  # open/create today's daily note
vn inbox                  # list unprocessed inbox notes
vn grep <pattern>         # full-text search (uses ripgrep)
vn promote <file>         # move note from inbox to zettelkasten
vn screenshot             # paste clipboard image as attachment
vn random                 # open a random zettel
vn orphans                # find notes with no incoming links
vn fix [--apply]          # normalize filenames (dry-run by default)
vn clean                  # delete empty inbox notes
```
