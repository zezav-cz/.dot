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
| `git-delta` | `git-delta` | apt | |
| `git-lfs` | `git-lfs` | apt | |
| `tig` | `tig` | apt | |

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
| `bat` | `bat` | apt | Package name is `bat`, but the installed binary is `/usr/bin/batcat` (Debian/Ubuntu renamed it to avoid a clash with the existing `bacula-console-qt`'s `bat` binary). Anything that shells out to `bat` on this host must use `batcat` (or the `~/.local/bin/bat -> batcat` symlink trick, not set up by this role). |
| `code` (VS Code) | `code` | repo | Not in the Ubuntu archive. Added Microsoft's apt repo per brief: key `https://packages.microsoft.com/keys/microsoft.asc` dearmored to `/etc/apt/keyrings/microsoft.gpg`, repo line `deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main`. Verified live: key URL returns HTTP 200, and `https://packages.microsoft.com/repos/code/dists/stable/Release` is a valid Release file (Origin: code stable). |

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

## Sway / Wayland utilities

| Fedora | Ubuntu | Type | Notes |
|---|---|---|---|
| *(not in list — see note)* | `waybar` | apt | **Addition beyond the literal `config.py` port.** `waybar` does not appear in `installer/config.py`'s Fedora list at all, because Fedora Sway Spin ships `waybar` in its base OS image — the installer never needed to manage it. Ubuntu has no equivalent spin, so it must be installed explicitly here; without it, Task 16's later requirement that `waybar` actually run on the Ubuntu desktop would be impossible to satisfy. This role's own Step-5 spot-check (`command -v waybar swaync code mise batcat`) confirms it's expected to resolve. Candidate `0.15.0-1` on Ubuntu 26.04. |
| `rofimoji` | `rofimoji` | apt | Available directly in the Ubuntu universe archive (candidate `6.7.0+dfsg-1`) — no pip/pipx fallback needed. |
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

## Summary

- Everything above resolved to a real Ubuntu 26.04 apt package **except**: `mise` and `code`
  (external apt repos), `fuse-libs` (redundant, covered by `fuse3`), `git-core` (redundant,
  covered by `git`), `nerd-fonts` (out of scope, handled by the `fonts` role),
  `cockpit-image-builder` and `cockpit-selinux` (no Ubuntu equivalent exists).
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
