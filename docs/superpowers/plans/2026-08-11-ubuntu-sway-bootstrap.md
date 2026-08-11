# Ubuntu Server + Sway Bootstrap (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get a working Sway session (greetd/tuigreet login, `foot` terminal, correct keyboard layout, working keybinds) booting on the Ubuntu 26.04 Server test KVM, using this repo's portable sway config fragments — proving the base layer before anything gets ported to Ansible.

**Architecture:** All work happens on a remote KVM over SSH (key-based auth already set up) plus `virsh` for console screenshots/keystrokes from the local libvirt host. Nothing in this repo's `stow/` tree is modified — the phase-1 sway config is assembled directly on the remote host from copies of the portable `config.d`/`modes.d` files, not stowed or symlinked (GNU Stow isn't part of phase 1's scope).

**Tech Stack:** Ubuntu 26.04 LTS (apt), sway 1.11, greetd + tuigreet, `rsync`, `virsh` (screenshot + send-key) for console verification.

## Global Constraints

- Target host: KVM at `192.168.124.68`, SSH user `jan`, key-based auth already working (verified — no password needed for SSH).
- Local libvirt domain name for this KVM: `ubu` (confirmed via `virsh list --all`).
- Ubuntu release: 26.04 LTS ("resolute"), confirmed via `/etc/os-release` on the box.
- Out of scope: waybar, swaync, gammastep, kanshi, theming, tailscale, screenshot/recording tools, wallpaper, WiFi/NetworkManager, laptop power management, Nerd Font install. None of these get touched in this plan.
- The repo's top-level `stow/sway/.config/sway/config` and `stow/sway/.config/sway/outputs` are NOT used on the remote host in this plan (see spec's Config Strategy section) — only these six files, copied verbatim: `config.d/variables.conf`, `config.d/keymaps.conf`, `config.d/appearance.conf`, `config.d/inputs.conf`, `config.d/custom-keymap.conf`, `modes.d/resize.conf`.
- Packages to install on the remote host: `sway` (1.11-3), `foot`, `greetd`, `tuigreet` (NOT `greetd-tuigreet` — confirmed that package name doesn't exist), `xwayland`, `fonts-noto`, `lxpolkit`.

---

## Task 1: Passwordless sudo for `jan` on the KVM

**Files:**
- Create (remote): `/etc/sudoers.d/90-jan-nopasswd`

**Interfaces:**
- Produces: passwordless `sudo` for user `jan` on this host only — every later task's remote commands rely on this (no interactive password prompts).

- [ ] **Step 1: Write the sudoers drop-in**

Run locally:
```bash
ssh jan@192.168.124.68 'echo "jan" | sudo -S sh -c "echo \"jan ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/90-jan-nopasswd && chmod 0440 /etc/sudoers.d/90-jan-nopasswd && visudo -cf /etc/sudoers.d/90-jan-nopasswd"'
```
Expected output: `/etc/sudoers.d/90-jan-nopasswd: parsed OK` (from `visudo -cf`, which validates syntax before we trust it).

- [ ] **Step 2: Verify passwordless sudo works**

Run: `ssh jan@192.168.124.68 'sudo -n true && echo NOPASSWD_OK'`
Expected: `NOPASSWD_OK` printed, no password prompt.

- [ ] **Step 3: Commit**

Nothing to commit locally — this change lives only on the remote KVM. No git commit for this task.

---

## Task 2: Install required packages

**Files:**
- None locally. Remote package state only (`dpkg` database).

**Interfaces:**
- Consumes: passwordless sudo from Task 1.
- Produces: `sway`, `foot`, `greetd`, `tuigreet`, `xwayland`, `fonts-noto`, `lxpolkit` binaries available on the remote host for Tasks 4–6.

- [ ] **Step 1: Update apt cache and install**

Run:
```bash
ssh jan@192.168.124.68 'sudo apt-get update -qq && sudo apt-get install -y sway foot greetd tuigreet xwayland fonts-noto lxpolkit'
```
Expected: exits 0, no `E:` errors in output.

- [ ] **Step 2: Verify each package installed**

Run:
```bash
ssh jan@192.168.124.68 'for p in sway foot greetd tuigreet xwayland fonts-noto lxpolkit; do dpkg -s "$p" >/dev/null 2>&1 && echo "OK $p" || echo "MISSING $p"; done'
```
Expected: `OK` printed for all seven packages, no `MISSING` lines.

- [ ] **Step 3: Verify sway binary and version**

Run: `ssh jan@192.168.124.68 'sway --version'`
Expected: `sway version 1.11.*`

- [ ] **Step 4: Commit**

Nothing to commit locally — remote package installation only.

---

## Task 3: Sync the `.dot` repo to the KVM

**Files:**
- Create (remote): `~/.dot/` (full rsync copy of the local working tree, including uncommitted changes)

**Interfaces:**
- Consumes: nothing from prior tasks.
- Produces: `~/.dot/stow/sway/.config/sway/config.d/*.conf` and `~/.dot/stow/sway/.config/sway/modes.d/resize.conf` on the remote host, used as the copy source in Task 4.

- [ ] **Step 1: rsync the working tree**

Run from the local repo root (`/home/jan/.dot`):
```bash
rsync -az --exclude='.git' ./ jan@192.168.124.68:~/.dot/
```
(`--exclude='.git'` keeps the transfer fast and avoids syncing local git internals that are irrelevant to the remote test — no `--delete`, since this is an additive sync onto a host that has nothing there yet.)

- [ ] **Step 2: Verify the portable sway files landed and match local content**

Run:
```bash
for f in variables.conf keymaps.conf appearance.conf inputs.conf custom-keymap.conf; do
  local_sum=$(sha256sum "stow/sway/.config/sway/config.d/$f" | cut -d' ' -f1)
  remote_sum=$(ssh jan@192.168.124.68 "sha256sum ~/.dot/stow/sway/.config/sway/config.d/$f | cut -d' ' -f1")
  [ "$local_sum" = "$remote_sum" ] && echo "OK $f" || echo "MISMATCH $f"
done
local_sum=$(sha256sum "stow/sway/.config/sway/modes.d/resize.conf" | cut -d' ' -f1)
remote_sum=$(ssh jan@192.168.124.68 "sha256sum ~/.dot/stow/sway/.config/sway/modes.d/resize.conf | cut -d' ' -f1")
[ "$local_sum" = "$remote_sum" ] && echo "OK resize.conf" || echo "MISMATCH resize.conf"
```
Expected: `OK` printed for all six files, no `MISMATCH` lines.

- [ ] **Step 3: Commit**

Nothing to commit locally — this is a one-way sync to the remote host, not a repo change.

---

## Task 4: Assemble the phase-1 sway config on the remote host

**Files:**
- Create (remote): `~/.config/sway/config.d/variables.conf` (copy)
- Create (remote): `~/.config/sway/config.d/keymaps.conf` (copy)
- Create (remote): `~/.config/sway/config.d/appearance.conf` (copy)
- Create (remote): `~/.config/sway/config.d/inputs.conf` (copy)
- Create (remote): `~/.config/sway/config.d/custom-keymap.conf` (copy)
- Create (remote): `~/.config/sway/modes.d/resize.conf` (copy)
- Create (remote): `~/.config/sway/config` (new, minimal, hand-written — NOT a copy of the repo's top-level config)

**Interfaces:**
- Consumes: `~/.dot/stow/sway/.config/sway/config.d/*` and `~/.dot/stow/sway/.config/sway/modes.d/resize.conf` from Task 3.
- Produces: `~/.config/sway/config` on the remote host — this is what `tuigreet` execs via `sway` in Task 5, and what Task 6 verifies against.

- [ ] **Step 1: Create the directory layout and copy the six portable files**

Run:
```bash
ssh jan@192.168.124.68 '
set -e
mkdir -p ~/.config/sway/config.d ~/.config/sway/modes.d
for f in variables.conf keymaps.conf appearance.conf inputs.conf custom-keymap.conf; do
  cp ~/.dot/stow/sway/.config/sway/config.d/"$f" ~/.config/sway/config.d/"$f"
done
cp ~/.dot/stow/sway/.config/sway/modes.d/resize.conf ~/.config/sway/modes.d/resize.conf
'
```

- [ ] **Step 2: Write the minimal top-level config**

Run:
```bash
ssh jan@192.168.124.68 'cat > ~/.config/sway/config <<'"'"'EOF'"'"'
set $mod Mod4

include $HOME/.config/sway/config.d/variables.conf
include $HOME/.config/sway/config.d/keymaps.conf
include $HOME/.config/sway/config.d/appearance.conf
include $HOME/.config/sway/config.d/inputs.conf
include $HOME/.config/sway/config.d/custom-keymap.conf
include $HOME/.config/sway/modes.d/*.conf

exec lxpolkit
EOF'
```
This is the phase-1-only file described in the spec: sources the six portable fragments, skips the wallpaper/`outputs` file/autostart block from the repo's real top-level config, adds only `lxpolkit` since that's the polkit agent installed in Task 2 (needed for anything that later triggers a polkit prompt — harmless to include now, nothing currently triggers one).

- [ ] **Step 3: Validate the config syntax**

Run: `ssh jan@192.168.124.68 'sway -c ~/.config/sway/config -C'`
Expected: exits 0, no `Error:` lines about unknown directives or missing includes. (`-C`/`--validate` checks syntax without needing a running graphical session — no DRM/seat access required, safe to run over plain SSH.)

- [ ] **Step 4: Commit**

Nothing to commit locally — remote-only file, per the spec (`stow/sway/` in the repo is untouched).

---

## Task 5: Configure and enable greetd + tuigreet

**Files:**
- Modify (remote): `/etc/greetd/config.toml`

**Interfaces:**
- Consumes: `tuigreet`/`sway` binaries from Task 2, `~/.config/sway/config` from Task 4 (implicitly — `tuigreet --cmd sway` execs `sway`, which reads the logged-in user's `~/.config/sway/config` by default).
- Produces: `greetd.service` active and owning tty1, ready for Task 6's login flow.

- [ ] **Step 1: Write the greetd config**

Run:
```bash
ssh jan@192.168.124.68 'echo "jan" | sudo -S tee /etc/greetd/config.toml > /dev/null <<'"'"'EOF'"'"'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd sway"
user = "greeter"
EOF'
```

- [ ] **Step 2: Enable and (re)start greetd**

Run: `ssh jan@192.168.124.68 'sudo systemctl enable --now greetd'`
Expected: exits 0. If greetd was already running from package install with default config, this restarts it with the new config.

- [ ] **Step 3: Verify greetd is active and owns tty1**

Run:
```bash
ssh jan@192.168.124.68 '
systemctl is-active greetd
systemctl is-active getty@tty1.service || echo "getty@tty1 inactive (expected — greetd owns tty1)"
'
```
Expected: first line `active`; second line either nothing (service not running, fine) or the "expected" message — either way, `getty@tty1` must NOT show `active`, since that would mean it's fighting greetd for tty1.

- [ ] **Step 4: Commit**

Nothing to commit locally — remote-only file.

---

## Task 6: End-to-end login and keybind verification

**Files:**
- None (verification only).

**Interfaces:**
- Consumes: everything from Tasks 1–5.
- Produces: pass/fail confirmation of the spec's success criteria — this is the task that actually closes out phase 1.

- [ ] **Step 1: Screenshot the console before login — confirm tuigreet is showing**

Run: `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/01-tuigreet.png`
Then view the image. Expected: a text-mode login prompt (tuigreet), not a raw `login:` getty prompt and not a blank/black screen.

- [ ] **Step 2: Type the username and submit**

Run:
```bash
for k in KEY_J KEY_A KEY_N; do virsh send-key ubu "$k"; sleep 0.2; done
virsh send-key ubu KEY_ENTER
sleep 1
```

- [ ] **Step 3: Type the password and submit**

Run:
```bash
for k in KEY_J KEY_A KEY_N; do virsh send-key ubu "$k"; sleep 0.2; done
virsh send-key ubu KEY_ENTER
sleep 3
```
(3s pause gives `sway` time to start after login.)

- [ ] **Step 4: Screenshot the console after login — confirm sway started**

Run: `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/02-sway-session.png`
Then view the image. Expected: a plain compositor background (not a text console, not a login prompt, not a black/error screen) — proves Sway actually launched after login, not just that greetd exists.

- [ ] **Step 5: Verify the sway process is running and its IPC socket resolves**

Run:
```bash
ssh jan@192.168.124.68 'pgrep -a -u jan sway'
ssh jan@192.168.124.68 'find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" 2>/dev/null'
```
Expected: first command shows a running `sway` process; second shows exactly one `sway-ipc.<uid>.<pid>.sock` path.

All later steps in this task resolve the socket inline via
`$(find /run/user/$(id -u jan) -maxdepth 1 -name 'sway-ipc*' | head -1)` rather than
requiring it to be copied from this step — this step exists only to confirm exactly
one socket exists before relying on that inline lookup.

- [ ] **Step 6: Verify keyboard layout via swaymsg**

Run:
```bash
ssh jan@192.168.124.68 'SWAYSOCK=$(find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" | head -1) swaymsg -t get_inputs' | grep -A3 '"type": "keyboard"'
```
Expected: output includes `"xkb_layout_names": [ "English (US)", "Czech" ]` (or equivalent showing both `us` and `cz` layouts configured) — proves `config.d/inputs.conf` loaded correctly.

- [ ] **Step 7: Verify the virtio output is detected**

Run: `ssh jan@192.168.124.68 'SWAYSOCK=$(find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" | head -1) swaymsg -t get_outputs'`
Expected: JSON showing one active output (the virtio GPU), `"active": true`.

- [ ] **Step 8: Live keybind test — `$mod+Return` opens `foot`**

Run:
```bash
virsh send-key ubu KEY_LEFTMETA KEY_ENTER
sleep 1
ssh jan@192.168.124.68 'SWAYSOCK=$(find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" | head -1) swaymsg -t get_tree' | grep -o '"app_id": "foot"'
```
Expected: `"app_id": "foot"` present in the tree — proves `variables.conf`'s `$term foot` and `keymaps.conf`'s `$mod+Return exec $term` both work end-to-end.

- [ ] **Step 9: Live keybind test — `$mod+2` switches workspace**

Run:
```bash
virsh send-key ubu KEY_LEFTMETA KEY_2
sleep 1
ssh jan@192.168.124.68 'SWAYSOCK=$(find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" | head -1) swaymsg -t get_workspaces' | grep -B2 '"focused": true' | grep '"num"'
```
Expected: `"num": 2` — proves `keymaps.conf`'s workspace-switch bindings work.

- [ ] **Step 10: Take a final confirmation screenshot**

Run: `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/03-foot-open.png`
Then view the image. Expected: a terminal window visible on screen, confirming Step 8's IPC-level check with a visual one.

- [ ] **Step 11: Commit**

Nothing to commit locally — this task is pure verification against the remote KVM. If all steps pass, phase 1 is complete: update the spec's status line.

Run:
```bash
cd /home/jan/.dot
```
Edit `docs/superpowers/specs/2026-08-11-ubuntu-sway-bootstrap-design.md`, changing `**Status:** Approved` to `**Status:** Phase 1 complete — verified on KVM 192.168.124.68 2026-08-11`.
```bash
git add docs/superpowers/specs/2026-08-11-ubuntu-sway-bootstrap-design.md
git commit -m "docs: mark phase 1 (Ubuntu Server + Sway bootstrap) as verified complete"
```
