# packages-full

Ports the Fedora `PACKAGES["fedora"]` list (`installer/config.py:44-120`) to real Ubuntu
26.04 (`resolute`) apt package names. Every mapping below was verified empirically against
the live KVM (192.168.124.68) with `apt-cache policy <name>` / `apt-cache show <name>`
before being added to `vars/main.yml` — nothing here is guessed.

Legend: **apt** = confirmed 1:1 (or renamed) apt package · **repo** = needs an external apt
repo · **dropped** = intentionally excluded, reason given.

## VCS & tools

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `git` | `git` | apt | |
| `git-delta` | `git-delta` | apt | Binary is `/usr/bin/delta` (package `git-delta`, per Debian/Ubuntu convention of prefixing ambiguous binary names) — confirmed already installed and resolving on the KVM. |
| `git-lfs` | `git-lfs` | apt | |
| `tig` | `tig` | apt | |
| *(not in list — see note)* | `lazygit` | apt | **Config-tool audit addition** (see the "Config-tool audit" section below). `stow/zsh/.zshrc` defines `alias lg='lazygit'`. Confirmed live: candidate `0.57.0+ds1-1` (universe). |

## Languages & build

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `ruby` | `ruby` | apt | |
| `ruby-devel` | `ruby-dev` | apt | |
| `golang` | `golang-go` | apt | Ubuntu also ships a `golang` meta-package that pulls in `golang-go` + `golang-doc` + `golang-src`; we install just the compiler/stdlib (`golang-go`) to match the intent of Fedora's `golang` without the extra doc/src bloat. |
| `mise` | `mise` | repo | Not in the Ubuntu archive. Added jdx's apt repo per brief: key `https://mise.jdx.dev/gpg-key.pub` dearmored to `/etc/apt/keyrings/mise.gpg`, repo line `deb [signed-by=/etc/apt/keyrings/mise.gpg arch=amd64] https://mise.jdx.dev/deb stable main`. Verified live: key URL returns HTTP 200, and `https://mise.jdx.dev/deb/dists/stable/Release` is a valid Release file (Origin: mise repository, Codename: stable). |
| `cmake` | `cmake` | apt | |

## CLI utils

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `wget` | `wget` | apt | |
| `curl` | `curl` | apt | |
| `fzf` | `fzf` | apt | |
| `bat` | `bat` | apt + shim | Package name is `bat`, but the installed binary is `/usr/bin/batcat` (Debian/Ubuntu renamed it to avoid a clash with the older, unrelated `bacula-console-qt`'s `bat` binary). `stow/zsh/.zshrc` uses `bat` directly (`alias cat='bat'`, `MANPAGER`, a dozen `bat -l <lang>` aliases) with no `command -v` guard, so this role now also symlinks `~/.local/bin/bat -> /usr/bin/batcat` (see "Renamed-binary shims" below). |
| *(not in list — see note)* | `fd-find` | apt + shim | **Config-tool audit addition.** `stow/mise/.config/mise/config.toml` declares `fd` as a mise tool, but `mise install` has never been run on this host (confirmed live: every entry in `mise ls` reports `(missing)`) and nothing in this repo runs it automatically — see the mise-deferred discussion below. In the meantime `fd` resolves to nothing at all: Debian/Ubuntu renames the package's own binary to `/usr/bin/fdfind` (its own compatibility symlink at `/usr/lib/cargo/bin/fd` is not on `$PATH`). Installed here and shimmed to `~/.local/bin/fd` so `fd` resolves today regardless of whether `mise install` has been run. |
| *(not in list — see note)* | `ripgrep` | apt | **Config-tool audit addition.** `stow/nvim/.config/nvim/lua/plugins/telescope.lua` shells out to `rg` for live-grep, and it underlies `fzf`'s default file/text search. Unlike `bat`/`fd`, Ubuntu does **not** rename ripgrep's binary — the `ripgrep` package installs directly as `/usr/bin/rg`, so no shim is needed. Confirmed live: candidate `15.1.0-1ubuntu1` (universe). |
| `code` (VS Code) | `code` | repo | Not in the Ubuntu archive. Added Microsoft's apt repo per brief: key `https://packages.microsoft.com/keys/microsoft.asc` dearmored to `/etc/apt/keyrings/microsoft.gpg`, repo line `deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main`. Verified live: key URL returns HTTP 200, and `https://packages.microsoft.com/repos/code/dists/stable/Release` is a valid Release file (Origin: code stable). |

### Renamed-binary shims

Two apt packages above install their binary under a different name than the
one the stowed configs actually invoke (`bat`→`batcat`, `fd-find`→`fdfind`).
`tasks/main.yml` creates `~/.local/bin/{bat,fd}` as `ansible.builtin.file`
symlinks (`state: link`, `force: true`, `follow: false`) pointing at the real
binaries, driven by the `packages_full_shims` var. `force: true` makes
re-running idempotent even if a stale symlink (or a real file, from some
manual experiment) already occupies the path; `follow: false` makes Ansible
compare/replace the symlink itself rather than whatever it resolves to.

`~/.local/bin` is confirmed live to be on `jan`'s `$PATH` for the actual
graphical session: `stow/systemd/.config/environment.d/path.conf` sets
`PATH="$HOME/.local/bin:$PATH"` for the systemd user manager, and inspecting
`/proc/<pid>/environ` of the live `sway`/`waybar` processes on the KVM (started
by greetd, not by this SSH session) confirms `PATH` does include
`/home/jan/.local/bin`. Note this is *not* true of a plain non-interactive SSH
command (its PATH comes from sshd's own PAM stack, which does not import
`environment.d`) — `ssh jan@host 'command -v bat'` before login-session PATH
propagation can be misleading; verification in this audit was cross-checked
against the live desktop session's actual environment, not just an SSH shell.

## Editors

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `vim` | `vim` | apt | |
| `neovim` | `neovim` | apt | |

## Dotfile management

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `stow` | `stow` | apt | |

## Shell

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| *(not in list — see note)* | `zsh` | apt | **Addition beyond the literal `config.py` port**, same category as `waybar` below. `zsh` does not appear in `installer/config.py`'s Fedora list because Fedora Sway Spin ships `zsh` in its base OS image — the installer never needed to manage it. Ubuntu has no equivalent spin (confirmed empirically: `command -v zsh` and `/usr/bin/zsh` both absent on the live KVM before this fix), so it must be installed explicitly here; without it, the `shell` role (Task 10), which sets `jan`'s login shell to `/usr/bin/zsh`, would have nothing to point at. |

## Containers

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `podman` | `podman` | apt | |

## Networking

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| *(not in list — see note)* | `tailscale` | repo | **Config-tool audit addition** (see below). `stow/sway/.config/sway/config` runs `exec sleep 3 && tailscale systray`. Not in the Ubuntu archive — added via Tailscale's own apt repo per `packages_full_repos`: key `https://pkgs.tailscale.com/stable/ubuntu/{{ ansible_distribution_release }}.gpg` (ASCII-armored variant, fits the existing dearmor pattern — the sibling `.noarmor.gpg` URL is already binary and would break `gpg --dearmor`) dearmored to `/etc/apt/keyrings/tailscale.gpg`, repo line `deb [signed-by=/etc/apt/keyrings/tailscale.gpg] https://pkgs.tailscale.com/stable/ubuntu {{ ansible_distribution_release }} main`. Verified live against the KVM's codename (resolute): both the key URL and the repo's Release file return HTTP 200. |

## Sway / Wayland utilities

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| *(not in list — see note)* | `waybar` | apt | **Addition beyond the literal `config.py` port.** `waybar` does not appear in `installer/config.py`'s Fedora list at all, because Fedora Sway Spin ships `waybar` in its base OS image — the installer never needed to manage it. Ubuntu has no equivalent spin, so it must be installed explicitly here; without it, Task 16's later requirement that `waybar` actually run on the Ubuntu desktop would be impossible to satisfy. This role's own Step-5 spot-check (`command -v waybar swaync code mise batcat`) confirms it's expected to resolve. Candidate `0.15.0-1` on Ubuntu 26.04. |
| *(not in list — see note)* | `rofi` | apt | **Config-tool audit addition, HIGH priority.** `stow/rofi/.config/rofi/config.rasi` is stowed and `stow/sway/.config/sway/config.d/variables.conf` defines `$rofi_cmd`/`$menu` on top of it — the `$mod+d` app launcher, the clipboard picker (`$mod+Shift+v`), and `screenrecord`'s audio-source prompt all invoke `rofi` directly. It was completely missing from the target before this fix, i.e. the launcher keybinding silently did nothing. Confirmed live: candidate `2.0.0-0.2` (universe). |
| `rofimoji` | `rofimoji` | apt | Available directly in the Ubuntu universe archive (candidate `6.7.0+dfsg-1`) — no pip/pipx fallback needed. |
| *(not in list — see note)* | `kanshi` | apt | **Config-tool audit addition.** `stow/sway/.config/sway/config` runs `exec kanshi` (its config is stowed at `stow/sway/.config/kanshi/config`) for output/profile management on hotplug. Confirmed live: candidate `1.9.0-1` (universe). |
| `grim` | `grim` | apt | |
| `slurp` | `slurp` | apt | |
| `wf-recorder` | `wf-recorder` | apt | |
| `swappy` | `swappy` | apt | |
| `wl-clipboard` | `wl-clipboard` | apt | |
| `geoclue2` | `geoclue-2.0` | apt | Confirmed via `apt-cache show`: "geoinformation service" — the daemon, matching Fedora's `geoclue2`. |
| `gammastep` | `gammastep` | apt | |
| `nwg-bar` | `nwg-bar` | apt | Available directly (candidate `0.1.6-1build1`, description "GTK3-based button bar for wlroots-based compositors") — no pip/pipx fallback needed, unlike the brief's worst-case expectation. |
| `nwg-displays` | `nwg-displays` | apt | Available directly (candidate `0.3.26-1`, description "output management utility for Wayland compositors like Sway") — no pip/pipx fallback needed. |
| `SwayNotificationCenter` | `sway-notification-center` | apt | Confirmed apt name per brief; candidate `0.12.4-1`. |
| *(not in list — see note)* | `brightnessctl` | apt | **Addition beyond the literal `config.py` port.** Task 15 ported `stow/sway/.config/sway/config.d/60-bindings-brightness.conf` verbatim from Fedora, which shells out to `brightnessctl`. Not in Fedora's `config.py` list because Fedora Sway Spin ships it in the base image. Confirmed live: candidate `0.5.1-3.1build1` (universe). |
| *(not in list — see note)* | `playerctl` | apt | **Addition beyond the literal `config.py` port.** `60-bindings-media.conf` (Task 15) shells out to `playerctl` for MPRIS media-key control; same base-image-only story as `waybar`. Confirmed live: candidate `2.4.1-3build1` (universe). |
| *(not in list — see note)* | `swayidle` | apt | **Addition beyond the literal `config.py` port.** `90-swayidle.conf` (Task 15) requires `swayidle` for the idle/lock daemon. Confirmed live: candidate `1.9.0-1` (universe). |
| *(not in list — see note)* | `swaylock` | apt | **Addition beyond the literal `config.py` port.** Same `90-swayidle.conf` (and `inputs.conf`'s lid-close binding) requires `swaylock` as the actual screen locker invoked by `swayidle`. Confirmed live: candidate `1.8.4-1` (universe). |
| *(not in list — see note)* | `pulseaudio-utils` | apt | **Addition beyond the literal `config.py` port.** `60-bindings-volume.conf` (Task 15) shells out to `pactl`, which `pulseaudio-utils` provides on Ubuntu (works against PipeWire's pulse-compat layer too). Confirmed live: candidate `1:17.0+dfsg1-2ubuntu4` (universe). |
| *(not in list — see note)* | `pavucontrol` | apt | **Config-tool audit addition.** `stow/sway/.config/waybar/config.jsonc`'s pulseaudio module has `"on-click": "pavucontrol"`. Confirmed live: candidate `6.1-1build1` (universe). |
| *(not in list — see note)* | `bluez` | apt | **Config-tool audit addition.** `stow/sway/.config/waybar/config.jsonc`'s bluetooth module has `"on-click": "foot -e bluetoothctl"`; `bluetoothctl` ships in the `bluez` package. Confirmed live: candidate `5.85-4ubuntu0.1` (main). |
| *(not in list — see note)* | `libnotify-bin` | apt | **Addition beyond the literal `config.py` port.** The brightness and volume binding fragments (Task 15) both optionally call `notify-send` for on-screen feedback; `libnotify-bin` provides it. Confirmed live: candidate `0.8.8-1` (main). |
| *(not in list — see note)* | `grimshot` | apt | **Addition beyond the literal `config.py` port.** `60-bindings-screenshot.conf` (Task 15) requires `grimshot` (Print/Alt+Print/Ctrl+Print bindings), distinct from the `grim`+`slurp` pair already in this list which `custom-keymap.conf`'s `$mod+Print` bindings use directly. Ships as its own apt package on Ubuntu, not bundled into `grim` or `sway`. Confirmed live: candidate `1.10.1-1build1` (universe). |

## FUSE (for AppImages)

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `fuse` | `fuse3` | apt | `fuse` exists on Ubuntu only as a transitional dummy package (`Depends: fuse3`, no real content) — installing `fuse3` directly. |
| `fuse-libs` | *(dropped)* | dropped | No standalone `fuse-libs`/`libfuse3-3` apt package exists on this host (`apt-cache policy libfuse3-3` returns nothing). `fuse3` already pulls in its own runtime library dependency automatically, so a separate entry is redundant. |

## Clipboard

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `cliphist` | `cliphist` | apt | Confirmed via `apt-cache show`: "wayland clipboard manager (program)". |

## SSH

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `openssh-askpass` | `ssh-askpass` | apt | `openssh-askpass` does not exist on Ubuntu. `ssh-askpass` (candidate `1:1.2.4.1-16build3`, description "under X, asks user for a passphrase for ssh-add") is the generic X11 askpass helper and is the closest functional match; chosen over the heavier `ssh-askpass-gnome` (which pulls in GNOME libs) since this is a Sway/wlroots desktop, not GNOME. |

## Fonts

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `nerd-fonts` | *(excluded)* | dropped | Explicitly out of scope for this role. Nerd Fonts are handled by the dedicated `fonts` role (Task 12), which downloads/installs font archives directly rather than via apt — Ubuntu has no `nerd-fonts` apt package anyway. |
| *(not in list — see note)* | `unzip` | apt | **Addition beyond the literal `config.py` port.** The `fonts` role (Task 12) uses `ansible.builtin.unarchive` with `remote_src: true` against `.zip` releases, which shells out to the `unzip` binary on the target. `unzip` was already present on the live KVM as a transitive dependency (auto-installed, not `apt-mark`ed manual) — not a guaranteed base-image package — so it's declared explicitly here for reproducibility. |
| *(not in list — see note)* | `fontconfig` | apt | **Addition beyond the literal `config.py` port.** Provides `fc-cache`, which the `fonts` role runs to refresh the font cache after extraction. Already present on the live KVM (transitive dependency of `qt6-qpa-plugins`/`libpango-1.0-0`), but declared explicitly so it isn't left to an incidental dependency chain. |

## Build dependencies

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `git-core` | *(dropped)* | dropped | Does not exist as an apt package on Ubuntu (`apt-cache policy git-core` shows no candidate). On Debian/Ubuntu, `git` already provides the core functionality Fedora splits into `git-core`; the separate `git` entry above covers it. |
| `zlib-devel` | `zlib1g-dev` | apt | |
| `libffi-devel` | `libffi-dev` | apt | |
| `readline-devel` | `libreadline-dev` | apt | |
| `openssl-devel` | `libssl-dev` | apt | |
| `make` | `make` | apt | |
| `gcc` | `gcc` | apt | |
| `patch` | `patch` | apt | |
| `autoconf` | `autoconf` | apt | |
| `automake` | `automake` | apt | |
| `bison` | `bison` | apt | |
| `libtool` | `libtool` | apt | |
| `sqlite-devel` | `libsqlite3-dev` | apt | |
| `libyaml-devel` | `libyaml-dev` | apt | |
| `libpcap-devel` | `libpcap-dev` | apt | |
| `libusb1-devel` | `libusb-1.0-0-dev` | apt | |

## Cockpit

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `cockpit-image-builder.noarch` | *(dropped)* | dropped | No Ubuntu apt package (`apt-cache policy cockpit-image-builder` returns nothing) — this is a Fedora/RHEL-specific bootc-image-builder integration with no Ubuntu counterpart in the archive. |
| `cockpit-packagekit.noarch` | `cockpit-packagekit` | apt | |
| `cockpit-podman.noarch` | `cockpit-podman` | apt | |
| `cockpit-selinux.noarch` | *(dropped)* | dropped | No Ubuntu apt package (`apt-cache policy cockpit-selinux` returns nothing) — expected, since Ubuntu's default MAC framework is AppArmor, not SELinux. |
| `cockpit-storaged.noarch` | `cockpit-storaged` | apt | |
| `cockpit-networkmanager` | `cockpit-networkmanager` | apt | |
| `pcp` | `pcp` | apt | |
| `python3-pcp` | `python3-pcp` | apt | |

Base `cockpit` package itself is not listed explicitly (mirroring the Fedora source list,
which also only lists the `cockpit-*` extras) — apt resolves it in automatically as a
dependency of the `cockpit-*` sub-packages.

## Misc

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `dbus-glib` | `libdbus-glib-1-2` | apt | `dbus-glib` is not a valid apt package name on Ubuntu; `libdbus-glib-1-2` is the equivalent runtime library package. |

## Games

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| `prismlauncher` | `prismlauncher` | apt | Available directly in the Ubuntu universe archive (candidate `10.0.5-2`, description "FOSS Minecraft launcher supporting multiple instances and accounts") — no PPA/flatpak fallback needed, unlike the brief's worst-case expectation. |

## Config-tool audit (final hardening wave)

Beyond porting `installer/config.py`'s Fedora package list, this section covers a full
sweep of every externally-invoked CLI binary referenced by the stowed configs
(`stow/sway/**` including `waybar/config.jsonc` + `waybar/scripts/*.sh`, `stow/zsh/.zshrc` +
`.zfunc/*`, `stow/tmux/.tmux.conf`, `stow/git/**`, `stow/foot/**`, `stow/rofi/**`,
`stow/k9s/**` including every `plugins/*.yaml`, `stow/my-scripts/.local/bin/*`, and
`stow/nvim/.config/nvim/lua/plugins/telescope.lua`), checked live against the KVM with
`command -v <bin>` (cross-checked against the real graphical session's `$PATH` where the
result depends on it — see "Renamed-binary shims" above). Tools that were already present or
newly added as apt/repo packages are listed in their category tables above (see the `rofi`,
`kanshi`, `pavucontrol`, `bluez`, `lazygit`, `tailscale`, `fd-find`, and `ripgrep` rows).
Already-present tools not re-tabled here: `waybar`, `grim`, `slurp`, `brightnessctl`,
`playerctl`, `swayidle`, `swaylock`, `pactl` (`pulseaudio-utils`), `grimshot`, `rofimoji`,
`cliphist`, `gammastep`, `swappy`, `wl-copy`/`wl-paste`, `batcat`, `fzf`, `delta`
(`git-delta`), `foot`, `swaynag`, `swaymsg`, `busctl`, `gsettings`, `swaync-client`,
`nwg-bar`, `wf-recorder`, `notify-send`, `xdg-user-dirs-update`, `jq`, `tmux`, `killall`,
`pkill`/`pgrep`, `ssh-add`, `sed`, `code`.

Tools intentionally **not** added, with reasoning:

| Tool | Where referenced | Decision | Reason |
|---|---|---|---|
| `slack` | `stow/sway/.config/sway/config`: `exec /bin/sh -c "command -v slack >/dev/null && slack -u"` | dropped | Ubuntu's apt package literally named `slack` (candidate `1:0.15.2-11build1`, `Depends: perl, rsync`) is **not** the Slack desktop chat client — verified via `apt-cache show slack`, it's an unrelated archival/backup utility. The real Slack desktop has no apt package on Ubuntu (would need its own `.deb`/snap from slack.com, outside this role's apt-only scope). The sway config already guards the exec with `command -v slack`, so this is a silent no-op rather than a broken keybinding; left as a manual/out-of-scope follow-up rather than adding a wrong package. |
| `kubectl` | `stow/zsh/.zshrc` (`alias k='kubectl '`) | deferred-to-mise | No apt package for `kubectl` exists in the Ubuntu archive at all (`apt-cache policy kubectl` returns no candidate). Fedora's own `installer/config.py` package list never lists `kubectl` either — on both distros it's expected to come from the user's personal `mise` toolchain (consistent with `k9s`, which is likewise a stow-managed config package here, not a `packages_full`/`PACKAGES["fedora"]` entry). Out of scope for this apt-only role. |
| `yq`, `gh`, `glab`, `cilium`, `hubble`, `jira`, `rcli`, `task`, `uv`, `ruff` | `stow/zsh/.zfunc/_yq`, `_gh`, `_glab`, `_cilium`, `_hubble`, `_jira`, `_rcli`, `_task`, `_uv`, `_ruff` (zsh completion scripts) | deferred-to-mise | This whole group of CLI tools ships its own zsh completion under `.zfunc`, the standard pattern for `mise`/`aqua`-managed per-user tool versions (this repo's own dev tooling, e.g. `uv`/`ruff`, is explicitly mise-managed per `CLAUDE.md`). None of them appear in `installer/config.py`'s Fedora package list either. Ubuntu *does* have an apt package literally named `yq` (candidate `3.4.3-2`), but it's the Python/kislyuk `yq` (jq wrapper), not the Go/mikefarah `yq` this completion script implies — installing it would risk shadowing a differently-versioned/behaved `yq` on `PATH`. Left to the user's own `mise install`, matching Fedora's design. |
| `mc`, `aws_completer`, `gcloud` | `stow/zsh/.zshrc`: `command -v mc`, `command -v aws_completer`, and a `mise`-install-path directory check for `gcloud` | deferred-to-mise / dropped | All three are already guarded with `command -v`/existence checks in `.zshrc` — their absence degrades gracefully (no broken keybinding or hard failure). `gcloud`'s own check (`$HOME/.local/share/mise/installs/gcloud`) confirms it's mise-managed by design. `mc` and `aws_completer` are optional shell-completion nice-to-haves, not exercised by any sway/waybar keybinding or script in this audit's scope; not added to keep `packages_full` focused on what the desktop environment actually needs to function. |
| `helm`, `dive`, `cmctl`, `crd-wizard` | `stow/k9s/.config/k9s/plugins/{helm-values,helm-diff,helm-default-values,dive,cert-manager,crd-wizard}.yaml` | deferred-to-mise | k9s power-user plugins invoked only when the user opens the matching resource view and presses the plugin's shortcut (e.g. `helm` view + a hotkey) — unlike a sway/waybar keybinding these have no always-on presence, so a missing binary degrades to "that one k9s hotkey errors," not a broken desktop. `helm` is already declared in `stow/mise/.config/mise/config.toml` (`helm = "4"`); `dive`, `cmctl`, `crd-wizard` have no apt package at all on Ubuntu (`apt-cache policy dive cmctl crd-wizard` returns no candidates for any of the three) — all are Go binaries from their own upstream releases, consistent with the mise/krew-managed tooling this k9s config already assumes for `kubectl` itself. |

**On `mise install` never having been run:** every tool in the "deferred-to-mise" rows above
(plus every entry in `stow/mise/.config/mise/config.toml`, including `fd`, which the table
above also handles via apt+shim so it resolves *today*) currently shows `(missing)` in
`mise ls` on the live KVM — `mise install` has never been executed there. This mirrors
Fedora's `install.py`, which also never runs `mise install` on the user's behalf; per
`CLAUDE.md`, `mise` tool activation/installation is the user's own responsibility, not this
role's. Nothing here changes that contract — it's confirmed working as designed, not a gap.

## Summary

- Everything above resolved to a real Ubuntu 26.04 apt package **except**: `mise`, `code`,
  and `tailscale` (external apt repos), `fuse-libs` (redundant, covered by `fuse3`),
  `git-core` (redundant, covered by `git`), `nerd-fonts` (out of scope, handled by the
  `fonts` role), `cockpit-image-builder` and `cockpit-selinux` (no Ubuntu equivalent exists).
- The config-tool audit (final hardening wave) added nine more packages after grepping every
  stowed config for externally-invoked binaries: `rofi` (HIGH priority — drives the
  `$mod+d` launcher and was completely missing), `kanshi`, `lazygit`, `pavucontrol`,
  `bluez`, `tailscale` (via its own apt repo), `fd-find`, `ripgrep`, and `bat` was already
  present (see below for why it still needed work). It deliberately did **not** add `slack`
  (Ubuntu's `slack` apt package is a same-named-but-unrelated tool, not the chat client),
  `kubectl` (mise-managed by design, matching Fedora), the `mise`/`aqua`-managed CLI
  group backing `stow/zsh/.zfunc/*` (`yq`, `gh`, `glab`, `cilium`, `hubble`, `jira`, `rcli`,
  `task`, `uv`, `ruff`), or the k9s power-user plugin tools `dive`/`cmctl`/`crd-wizard`/`helm`
  (no apt package, or already mise-managed). See the "Config-tool audit" section above for
  the full table.
- **Audit close-out (this pass):** two binaries the stowed configs invoke by their
  upstream-conventional name resolve to nothing on stock Ubuntu because the distro renames
  the package's own binary — `bat`→`batcat`, `fd-find`→`fdfind`. Both are now shimmed to
  `~/.local/bin/{bat,fd}` via a new idempotent `ansible.builtin.file` symlink task (see
  "Renamed-binary shims" above). `ripgrep` was simply missing outright (not a rename — its
  binary is `rg` natively) and is now installed. Re-verified live against the KVM after a
  full playbook re-run: every non-optional, non-mise-deferred binary referenced anywhere in
  `stow/**` now resolves via `command -v`.
- No package required a pip/pipx fallback — every Sway/wlroots utility Fedora sources from
  COPR (`nwg-bar`, `nwg-displays`, `rofimoji`, `cliphist`, `SwayNotificationCenter`,
  `prismlauncher`) turned out to have a native apt package in Ubuntu's universe archive.
- Four packages were **added** beyond the literal `config.py` port: `waybar` and `zsh` (both
  absent from Fedora's list because Fedora Sway Spin bundles them in the base image; Ubuntu
  has no such spin), and `unzip`/`fontconfig` (tooling the `fonts` role, Task 12, depends on
  for `unarchive`/`fc-cache` but which `config.py` never had to declare since the Python
  installer used `zipfile` directly). See the Sway / Wayland utilities, Shell, and Fonts
  tables.
- Seven more packages were **added** as a Task 16 prerequisite fix: `brightnessctl`,
  `playerctl`, `swayidle`, `swaylock`, `pulseaudio-utils`, `libnotify-bin`, and `grimshot` —
  all binaries that Task 15's ported sway `config.d/` keybinding fragments (brightness,
  media, idle/lock, volume, screenshot) shell out to, but which this role hadn't declared
  yet. Same base-image story as `waybar`/`zsh`: Fedora Sway Spin ships these in its base
  image, so `config.py` never needed to list them. All seven confirmed live against the KVM
  with `apt-cache policy`. See the Sway / Wayland utilities table.
