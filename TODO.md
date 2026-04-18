# TODO

## High Priority

- [ ] **swayidle** — No idle/lock timeout configured. Swaylock exists but nothing triggers it on idle.
- [ ] **SSH config** (`~/.ssh/config`) — ssh-agent service exists but no host/key configuration.
- [ ] **direnv** — Per-project env var management. Works well alongside mise.
- [ ] **`.inputrc`** — Readline config (vi mode, completion). Affects bash, python REPL, etc.

## Medium Priority

- [ ] **GPG agent config** — Keyring/signing setup for signed git commits.
- [ ] **XDG user-dirs** (`user-dirs.dirs`) — Explicit Desktop/Documents/Downloads mapping.
- [ ] **npm/pip config** (`.npmrc`, `pip.conf`) — Package manager config for mise-managed runtimes.
- [ ] **dconf dump/restore** — Backup GNOME/gsettings (sway config sets them but no restore mechanism).
- [ ] **`.bashrc`** — Bash fallback if zsh breaks or SSH without zsh.

## Low Priority / Nice-to-have

- [ ] Cursor/icon theme config
- [ ] Podman user config (beyond syncthing container)
- [ ] `.ripgreprc` — ripgrep configuration
- [ ] Obsidian vault settings — AppImage installed but vault config not stowed
- [ ] Zotero installation — removed from installer, needs re-adding

## Packages to Add

- [ ] gnome-themes-extra
- [ ] docker (for recombee)
- [ ] papirus-icon-theme
- [ ] `@virtualization` group
- [ ] pcsc-lite, pcsc-lite-devel, pcsc-tools, swig (smartcard support)

## nwg-shell Tools to Evaluate

- nwg-shell-config
- nwg-bar
- nwg-clipman
- nwg-dock
- nwg-drawer
- nwg-look
- nwg-menu
- nwg-panel
