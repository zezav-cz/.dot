# Ansible for Ubuntu (Phase 2)

**Status:** Phase 2 complete — verified end-to-end from a bare Ubuntu 26.04
reinstall on KVM 192.168.124.68 (2026-08-13): both playbooks run clean and
idempotent from scratch, full waybar desktop renders after reboot.
**Date:** 2026-08-11

> **Prerequisites (later change):** the `bootstrap-auth` role was removed.
> The operator now guarantees, outside Ansible (image/preseed), that the
> target already has SSH key access and `NOPASSWD` sudo for the login user.
> With `NOPASSWD`, Ansible `become` uses `sudo -n` (no prompt), which also
> sidesteps Ubuntu 26.04's `sudo-rs` prompt-format incompatibility — so no
> in-playbook sudo switch or become password is needed.

## Context

Phase 1 (see `2026-08-11-ubuntu-sway-bootstrap-design.md`) proved Sway boots
on Ubuntu Server via a hand-assembled, ad-hoc setup driven by a human
operator through SSH. That work is not repeatable or idempotent, and it
deliberately stopped short of the full desktop (no waybar, swaync,
gammastep, kanshi, full package set, shell, apps, fonts).

Phase 2 replaces that ad-hoc process with Ansible: two playbooks that
together bring the same KVM (`192.168.124.68`, libvirt domain `ubu`, user
`jan`) to full parity with what a Fedora `install.py` run produces, in a
form that can be re-run safely and repeatedly. Phase 3 (extending the same
playbooks to Fedora and retiring the Python installer) is out of scope
here — `install.py` is not touched by this work.

## Goal

Two playbooks, each independently re-runnable and idempotent (a second run
of either must report zero `changed` tasks):

1. **`playbook-sway-base.yml`** — usable on a bare Ubuntu server with no
   dotfiles repo access at all. Installs Sway, a terminal, and a working
   login screen. This is phase 1's exact functional scope, reimplemented
   properly instead of assembled by hand over SSH.
2. **`playbook-environment.yml`** — assumes playbook 1 already ran.
   Replicates the rest of `install.py`'s behavior for Ubuntu: full package
   parity, the complete dotfiles `stow` set, shell, apps, fonts, VNotes,
   MCP servers, and the fixes needed to make the *real* sway config (not
   phase 1's stripped-down one) work on Ubuntu.

## Architecture

New `ansible/` directory at the repo root. `ansible-core` is added to
`mise.toml` (installed via the `pipx:ansible-core` mise backend), per this
repo's tooling convention of declaring every tool there.

```
ansible/
  playbook-sway-base.yml
  playbook-environment.yml
  inventory.yml
  roles/
    packages-base/
    greetd/
    sway-minimal/
    packages-full/
    stow/
    shell/
    apps/
    fonts/
    vnotes/
    mcp/
    sway-portability/
```

### `playbook-sway-base.yml`

Runs against a target that already has SSH key access and `NOPASSWD` sudo
(operator-provided). No git, no GitHub, no repo checkout required.

- **`packages-base`** — apt-installs `sway`, `foot`, `greetd`, `tuigreet`,
  `xwayland`, `lxpolkit`. Exactly phase 1's package list.
- **`greetd`** — writes `/etc/greetd/config.toml`
  (`command = "tuigreet --cmd sway"`, `user = "_greetd"`). Uses Ubuntu's
  own `_greetd` system user (created by the `greetd` package itself) —
  **not** phase 1's redundant hand-created `greeter` user, which phase 1's
  own final review flagged as the wrong long-term identity. Replaces phase
  1's blanket `systemctl mask getty@tty1` with a proper
  `Conflicts=getty@tty1.service` systemd drop-in — phase 1 found Ubuntu's
  shipped `greetd.service` assumes vt7, not vt1, which is *why* tty1 had
  to be masked by hand; a drop-in expresses the real fix declaratively and
  reversibly instead.
- **`sway-minimal`** — embeds its own copies of the six portable config
  fragments phase 1 identified as safe (`variables.conf`, `keymaps.conf`,
  `appearance.conf`, `inputs.conf`, `custom-keymap.conf`,
  `modes.d/resize.conf`) as Ansible role files, templated into
  `~/.config/sway/`. These are copies, not symlinks — this role has no
  dependency on the `.dot` repo being present on the target at all. A
  minimal top-level `~/.config/sway/config` (same shape as phase 1's
  hand-written one) sources them.

After this playbook: a bare server reaches exactly phase 1's end state,
idempotently.

### `playbook-environment.yml`

Assumes `playbook-sway-base.yml` has already run (key auth and base
packages are in place). Not designed to run standalone on a box that
hasn't seen playbook 1.

- **`packages-full`** — the full apt package list, ported from
  `installer/config.py`'s `PACKAGES["fedora"]` list. Lives in its own
  `ansible/roles/packages-full/vars/main.yml`, independent of
  `installer/config.py`'s `PACKAGES["debian"]` stub (which stays
  untouched — avoiding two systems' package lists needing to stay in sync
  during the transition; `install.py`'s debian path is not this phase's
  concern, and phase 3 retires it anyway). Every entry gets verified
  empirically against the real KVM during implementation, the same way
  phase 1 discovered `tuigreet` (not `greetd-tuigreet`) by checking
  `apt-cache` directly rather than assuming Debian naming conventions.
  Packages without a clean apt equivalent (candidates: `cliphist`,
  `SwayNotificationCenter`/swaync, `nwg-bar`, `nwg-displays`, `rofimoji`,
  VS Code, `mise`, `prismlauncher`, the Fedora-only `cockpit-*` extras)
  get a documented per-package resolution during implementation (PPA,
  snap, direct `.deb`, build-from-source, or an explicit "dropped for
  Ubuntu, here's why").
- **`stow`** — clones `.dot` over public HTTPS
  (`https://github.com/zezav-cz/.dot.git`, the repo is public — no
  credentials) to `~/.dot` on the target, then runs the same `stow`
  invocations `installer/steps/s06_stow.py` does: full `STOW_PACKAGES`
  set, `--no-folding` for `STOW_NO_FOLDING`, backing up a pre-existing
  non-symlink `~/.zshrc`, and cloning `lazy.nvim`. This **supersedes**
  `sway-minimal`'s embedded copies with real symlinks from the cloned
  repo — running this playbook is expected to change every file
  `sway-minimal` created. (Originally used a generated read-only deploy
  key; simplified once `.dot` went public.)
- **`shell`** — oh-my-zsh + plugins (`zsh-autosuggestions`,
  `zsh-syntax-highlighting`, `zsh-completions`) + default shell, porting
  `installer/steps/s03_shell.py`'s logic. Distro-agnostic already (git
  clones), mechanical translation.
- **`apps`** — AppImage installs (Obsidian, Headlamp, Signal — GPG
  verification, desktop entries), porting `installer/steps/s04_apps.py`.
  Distro-agnostic already aside from needing `fuse3` (covered by
  `packages-full`, not `fuse`/`fuse-libs` as on Fedora).
- **`fonts`** — Nerd Fonts + Font Awesome download/extract, porting
  `installer/steps/s05_fonts.py`. Fully distro-agnostic (direct URL
  downloads).
- **`vnotes`** — clones/pulls the VNotes repo, porting
  `installer/steps/s07_vnotes.py`. Distro-agnostic.
- **`mcp`** — registers Claude Code MCP servers into `~/.claude.json`,
  porting `installer/steps/s08_mcp.py`. Distro-agnostic, no system
  packages involved.
- **`sway-portability`** — the substantive new work. Fedora's sway package
  ships 13 OS-level config fragments under `/usr/share/sway/config.d/`
  (readable directly on the current machine, which *is* the Fedora box)
  that the repo's real `stow/sway/.config/sway/config` depends on via a
  Fedora-specific `layered-include` mechanism that doesn't exist on
  Ubuntu. Two of these are functionally critical and were never tested in
  phase 1 because phase 1 didn't use the real config:
  - `bar { swaybar_command waybar }` — **nothing else starts waybar.**
    Without an equivalent, installing and stowing waybar's own config
    (via `packages-full` and `stow` above) is not suffient to make it
    appear on screen.
  - PolicyKit agent autostart (Fedora's fragment execs
    `lxqt-policykit-agent`; this repo already runs `lxpolkit` instead per
    phase 1's choice, so this specific piece needs no new work, just
    confirmation it still fires from the real config).

  This role brings repo-owned, distro-agnostic equivalents of the
  essential fragments (bar activation, the brightness/media/volume/
  screenshot keybindings, xdg-desktop-autostart, xdg-user-dirs,
  swayidle) into `stow/sway/` itself — landing in the repo, not just on
  this one Ubuntu box, so Fedora benefits too once phase 3 unifies the
  installers. Also fixes the orphaned `$volume_limit` variable
  (`variables.conf`'s comment currently points at
  `/usr/share/sway/config.d/60-bindings-volume.conf`, which won't exist
  once this role supersedes reliance on that path).

## Testing / verification

- **Idempotency:** each playbook run twice in sequence; the second run of
  each must report zero `changed` tasks. This is the primary correctness
  signal for Ansible work and gets checked for both playbooks
  independently.
- **Live re-verification, playbook 1:** after `playbook-sway-base.yml`,
  redo phase 1's proof — `virsh reboot`, `virsh screenshot`/`send-key` —
  confirming tuigreet renders, login works, `$mod+Return` opens `foot`,
  keyboard layout and output are correct. Same bar phase 1 already
  cleared, now via a repeatable playbook instead of a one-off session.
- **Live re-verification, playbook 2:** after `playbook-environment.yml`,
  a further reboot/login cycle confirming the *real* desktop actually
  renders — specifically that waybar and swaync appear on screen (phase 1
  never tested this; `sway-portability` exists specifically to make it
  true), and that the full `STOW_PACKAGES` set landed as real symlinks
  (spot-check a few, e.g. `~/.config/nvim` resolves into the repo).
- Playbook 1 verified end-to-end on KVM (reboot + tuigreet + foot) 2026-08-11.
- Playbook 2 (`playbook-environment.yml`) verified end-to-end on KVM
  2026-08-11: two consecutive full runs both idempotent (second run
  `changed=0` across all 37 tasks); `virsh reboot` + tuigreet greeter
  screenshot + send-key login; **waybar and swaync confirmed on-screen** —
  `virsh screenshot` of the live desktop shows the waybar bar rendered
  across the top (workspace indicator, tray, clock), and `pgrep -a -u jan
  waybar`/`swaync` both show running processes; `systemctl --user
  show-environment` confirms `DISPLAY`/`WAYLAND_DISPLAY`/`SWAYSOCK` are now
  imported into the systemd user manager (phase 1's env-import finding
  resolved). Stow symlink spot-check (`~/.config/nvim`, `~/.config/foot`,
  `~/.config/sway/config`, `~/.tmux.conf`) all resolve into
  `~/.dot/stow/...`. One residual, non-blocking finding surfaced during
  this pass: `systemctl --user is-active graphical-session.target` still
  reports `inactive` — nothing in stock Ubuntu's sway packaging or this
  repo's config ever issues `systemctl --user start
  graphical-session.target`, so the target itself never activates even
  though the env vars it would carry are correctly imported and waybar/
  swaync run fine as direct `exec`-launched processes rather than via
  their (Ubuntu-packaged, and here redundant/crash-looping)
  `waybar.service`/`swaync.service` units. Left as a follow-up, not fixed
  here — out of this task's verification-only scope.

## Out of scope

- Modifying `install.py` or `installer/config.py`'s existing Fedora/debian
  package data — phase 3's concern.
- WiFi/NetworkManager, laptop power management — still deferred to a
  laptop-specific pass, as phase 1 stated.
- Fixing `installer/config.py`'s `PACKAGES["debian"]` stub — this phase's
  package list lives independently in the Ansible role, not there.
- Provisioning the target's auth prerequisites (SSH key + `NOPASSWD` sudo)
  — these are operator-provided outside Ansible; the playbooks assume them.
