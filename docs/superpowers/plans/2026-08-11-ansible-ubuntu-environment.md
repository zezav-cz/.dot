# Ansible for Ubuntu (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two idempotent Ansible playbooks that bring the Ubuntu 26.04 test KVM to full parity with a Fedora `install.py` run — `playbook-sway-base.yml` (bare-server Sway + login screen, self-contained) and `playbook-environment.yml` (full package/stow/shell/apps/fonts/vnotes/mcp parity + the sway portability fixes).

**Architecture:** New `ansible/` dir at repo root; `ansible-core` added to `mise.toml`. The control node is this Fedora machine; the managed node is the KVM. Playbook 1 is self-contained (no repo checkout on target). Playbook 2 clones `.dot` on the target and stows it. `install.py` and `installer/` are NOT modified — this is a parallel path for Ubuntu.

**Tech Stack:** Ansible (ansible-core via mise `pipx:` backend), `ansible.posix` and `community.general` collections, `sshpass` (already installed on control node), `virsh` (screenshot/send-key verification), `gh` CLI (already authenticated to `zezav-cz/.dot`).

## Global Constraints

- Managed node: KVM at `192.168.124.68`, SSH user `jan`, libvirt domain `ubu` (for `virsh`). Control node is `/home/jan/.dot` on this Fedora machine.
- Password-auth SSH wrapper (for the pre-key bootstrap and any manual check): `/tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/kvm-ssh '<cmd>'`. Account password is `jan`.
- **Idempotency is the primary acceptance signal:** every playbook, run a second time immediately, must report `changed=0` in its recap. A task that can't be made idempotent is a defect.
- **Auth posture (hard rules from phase 1 spec):** `bootstrap-auth` installs a dedicated SSH key and disables empty-password SSH (`PermitEmptyPasswords no`) to close the no-auth gap. `NOPASSWD` sudo STAYS (accepted for this box). No Ansible role may set a blank password, set `PermitEmptyPasswords yes`, or configure blanket `NOPASSWD` sudo — those are the phase-1-forbidden posture.
- `install.py`, `installer/config.py`, and `installer/steps/` are OUT OF SCOPE — do not modify them. The Ansible package list lives in the role's own vars, not in `installer/config.py`.
- Ansible content must pass `ansible-lint` (added in Task 1) and `ansible-playbook --syntax-check`.
- The KVM currently holds phase-1's hand-assembled `~/.config/sway/` (plain files, not symlinks). Playbook 2's `stow` role is expected to replace those with symlinks — that replacement is intended, not a conflict to preserve.
- Package names must be verified empirically against the real KVM (`apt-cache policy <pkg>`), never assumed from Debian naming conventions — phase 1 found `tuigreet`, not `greetd-tuigreet`, this way.

### Source-of-truth references (read these; do not re-derive)

- Fedora package list to port: `installer/config.py:44-120` (`PACKAGES["fedora"]`).
- Apps: `installer/config.py:241-270` (`APPS` — obsidian 1.10.6, headlamp 0.43.0, signal-desktop unversioned+GPG). Logic: `installer/steps/s04_apps.py`.
- Fonts: `installer/config.py:199-212` (`EXTRA_FONTS`), `NERD_FONTS_VERSION = "v3.4.0"` at `:188`. Logic: `installer/steps/s05_fonts.py`. Target dir `~/.local/share/fonts/{nerd-fonts,fontawesome-6-console}`.
- zsh plugins: `installer/config.py:276-280` (zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions). Logic: `installer/steps/s03_shell.py`.
- Stow packages: `installer/config.py:285-301` — `STOW_PACKAGES = [git, mise, nvim, rofi, ssh-agent, sway, systemd, tmux, zsh, foot, k9s, nwg-displays]`, `STOW_NO_FOLDING = [my-scripts, pgcli, vscode]`. Logic: `installer/steps/s06_stow.py`. lazy.nvim: repo `https://github.com/folke/lazy.nvim.git` → `~/.local/share/nvim/lazy/lazy.nvim`.
- VNotes: `git@github.com:zezav-cz/vnotes.git` → `~/vnotes`. Logic: `installer/steps/s07_vnotes.py`.
- MCP servers: `installer/config.py:319-336` (sequential-thinking, vnotes filesystem, kubernetes-mcp-server). Logic: `installer/steps/s08_mcp.py` — merge-only into `~/.claude.json`, never clobber.
- Fedora sway fragments to port: `/usr/share/sway/config.d/` ON THIS CONTROL MACHINE (it IS the Fedora box). Read them directly.

---

## Task 1: Ansible scaffolding + tooling

**Files:**
- Modify: `mise.toml` (add `ansible-core`, `ansible-lint`)
- Create: `ansible/ansible.cfg`
- Create: `ansible/inventory.yml`
- Create: `ansible/requirements.yml`
- Create: `ansible/playbook-sway-base.yml` (skeleton)
- Create: `ansible/playbook-environment.yml` (skeleton)
- Create: `ansible/.gitignore`

**Interfaces:**
- Produces: an `ansible/` tree where `ansible-playbook --syntax-check` passes; inventory group `sway_hosts` with host `ubu` (`ansible_host=192.168.124.68`, `ansible_user=jan`); the dedicated key path convention `~/.ssh/dot_ansible_ed25519` (created in Task 2, referenced here).

- [ ] **Step 1: Add ansible tooling to mise.toml**

Under `[tools]` in `mise.toml`, add:
```toml
"pipx:ansible-core" = "2.18"
"pipx:ansible-lint" = "latest"
```
Then run `mise install` and confirm `ansible-playbook --version` and `ansible-lint --version` both work.

- [ ] **Step 2: Write ansible/ansible.cfg**

```ini
[defaults]
inventory = inventory.yml
roles_path = roles
host_key_checking = False
stdout_callback = yaml
nocows = True
interpreter_python = auto_silent

[ssh_connection]
pipelining = True
```

- [ ] **Step 3: Write ansible/inventory.yml**

```yaml
sway_hosts:
  hosts:
    ubu:
      ansible_host: 192.168.124.68
      ansible_user: jan
      ansible_ssh_private_key_file: ~/.ssh/dot_ansible_ed25519
```

- [ ] **Step 4: Write ansible/requirements.yml and install collections**

```yaml
collections:
  - name: ansible.posix
  - name: community.general
```
Run: `cd ansible && ansible-galaxy collection install -r requirements.yml`

- [ ] **Step 5: Write ansible/.gitignore**

```gitignore
*.retry
```

- [ ] **Step 6: Write both playbook skeletons**

`ansible/playbook-sway-base.yml`:
```yaml
---
- name: Sway base (bare-server Sway + login screen)
  hosts: sway_hosts
  become: false
  roles: []
```
`ansible/playbook-environment.yml`:
```yaml
---
- name: Environment (full install.py parity for Ubuntu)
  hosts: sway_hosts
  become: false
  roles: []
```

- [ ] **Step 7: Syntax check both**

Run: `cd ansible && ansible-playbook --syntax-check playbook-sway-base.yml playbook-environment.yml`
Expected: both report no syntax errors. (They do nothing yet — empty roles list.)

- [ ] **Step 8: Commit**

```bash
git add mise.toml ansible/
git commit -m "chore(ansible): scaffold ansible tree and add ansible-core to mise"
```

---

## Task 2: `bootstrap-auth` role

**Files:**
- Create: `ansible/roles/bootstrap-auth/tasks/main.yml`
- Modify: `ansible/playbook-sway-base.yml` (add role, add a password-bootstrap pre_task pattern)

**Interfaces:**
- Consumes: nothing (first role).
- Produces: dedicated keypair `~/.ssh/dot_ansible_ed25519[.pub]` on the control node; its pubkey in `jan`'s `authorized_keys` on the KVM; `PermitEmptyPasswords no` in the KVM's sshd. After this role, all connections use the key (matching `inventory.yml`).

- [ ] **Step 1: Generate the dedicated control-node keypair (idempotent, run on control node)**

This is a control-node prerequisite, done once by hand (not in the role, since it's local):
```bash
test -f ~/.ssh/dot_ansible_ed25519 || ssh-keygen -t ed25519 -N '' -C 'ansible@dot' -f ~/.ssh/dot_ansible_ed25519
```

- [ ] **Step 2: Write the bootstrap-auth role tasks**

`ansible/roles/bootstrap-auth/tasks/main.yml`:
```yaml
---
- name: Install dedicated Ansible SSH public key for jan
  ansible.posix.authorized_key:
    user: jan
    key: "{{ lookup('file', lookup('env', 'HOME') + '/.ssh/dot_ansible_ed25519.pub') }}"
    state: present

- name: Disable empty-password SSH logins (close the no-auth gap)
  become: true
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?\s*PermitEmptyPasswords'
    line: 'PermitEmptyPasswords no'
    validate: 'sshd -t -f %s'
  notify: Restart sshd

- name: Confirm NOPASSWD sudo still works over the key connection
  become: true
  ansible.builtin.command: 'true'
  changed_when: false
```

- [ ] **Step 3: Add the handler**

`ansible/roles/bootstrap-auth/handlers/main.yml`:
```yaml
---
- name: Restart sshd
  become: true
  ansible.builtin.service:
    name: ssh
    state: restarted
```

- [ ] **Step 4: Wire bootstrap-auth into playbook-sway-base.yml with a password-bootstrap fallback**

Replace the play in `ansible/playbook-sway-base.yml` with a first play that can reach the box even before the key is installed, by trying the key and falling back to password. The clean way: run `bootstrap-auth` with a password-capable connection the first time. Set it up as:
```yaml
---
- name: Bootstrap auth (key handoff)
  hosts: sway_hosts
  become: false
  gather_facts: false
  vars:
    # Allow password fallback for the very first connect (blank password today).
    ansible_ssh_common_args: '-o PreferredAuthentications=publickey,password -o PubkeyAcceptedKeyTypes=+ssh-ed25519 -o StrictHostKeyChecking=no'
  roles:
    - bootstrap-auth

- name: Sway base
  hosts: sway_hosts
  become: false
  roles: []
```
Note: the box currently accepts any password (blank-password state), so the first connect succeeds via the existing key (phase 1 left `jan`'s own key in `authorized_keys`) OR password; either way `authorized_key` then installs the dedicated key. If the run cannot connect at all, pass `-e ansible_ssh_pass=jan -e ansible_ssh_common_args='-o PubkeyAuthentication=no -o PreferredAuthentications=password'` for the first invocation only (document this in the role's a `README` note). After the dedicated key is in place, plain `ansible-playbook` uses it.

- [ ] **Step 5: Run and verify key auth + gap closure**

Run: `cd ansible && ansible-playbook playbook-sway-base.yml`
Then independently verify:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 -o PreferredAuthentications=publickey -o PubkeyAuthentication=yes jan@192.168.124.68 'echo KEY_AUTH_OK; sudo -n true && echo NOPASSWD_OK'
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'sudo grep -i permitemptypasswords /etc/ssh/sshd_config'
```
Expected: `KEY_AUTH_OK`, `NOPASSWD_OK`, and `PermitEmptyPasswords no`.

- [ ] **Step 6: Verify idempotency**

Run: `cd ansible && ansible-playbook playbook-sway-base.yml` a second time.
Expected: recap shows `changed=0` for the bootstrap-auth play.

- [ ] **Step 7: Commit**

```bash
git add ansible/roles/bootstrap-auth ansible/playbook-sway-base.yml
git commit -m "feat(ansible): bootstrap-auth role — install key, close empty-password gap"
```

---

## Task 3: `packages-base` role

**Files:**
- Create: `ansible/roles/packages-base/tasks/main.yml`
- Create: `ansible/roles/packages-base/vars/main.yml`
- Modify: `ansible/playbook-sway-base.yml` (add role to the "Sway base" play)

**Interfaces:**
- Consumes: key auth from Task 2.
- Produces: `sway`, `foot`, `greetd`, `tuigreet`, `xwayland`, `lxpolkit` installed on the KVM (idempotent).

- [ ] **Step 1: Write vars**

`ansible/roles/packages-base/vars/main.yml`:
```yaml
---
packages_base:
  - sway
  - foot
  - greetd
  - tuigreet
  - xwayland
  - lxpolkit
```

- [ ] **Step 2: Write tasks**

`ansible/roles/packages-base/tasks/main.yml`:
```yaml
---
- name: Install base Sway packages
  become: true
  ansible.builtin.apt:
    name: "{{ packages_base }}"
    state: present
    update_cache: true
    cache_valid_time: 3600
```

- [ ] **Step 3: Add role to the Sway base play**

In `ansible/playbook-sway-base.yml`, set the second play's `roles:` to `[packages-base]`.

- [ ] **Step 4: Run and verify**

Run: `cd ansible && ansible-playbook playbook-sway-base.yml`
Then: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'for p in sway foot greetd tuigreet xwayland lxpolkit; do dpkg -s "$p" >/dev/null 2>&1 && echo "OK $p" || echo "MISSING $p"; done'`
Expected: `OK` for all six.

- [ ] **Step 5: Verify idempotency**

Run the playbook again; expected `changed=0`.

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/packages-base ansible/playbook-sway-base.yml
git commit -m "feat(ansible): packages-base role"
```

---

## Task 4: `greetd` role

**Files:**
- Create: `ansible/roles/greetd/tasks/main.yml`
- Create: `ansible/roles/greetd/templates/config.toml.j2`
- Create: `ansible/roles/greetd/files/getty-conflict.conf`
- Modify: `ansible/playbook-sway-base.yml`

**Interfaces:**
- Consumes: `greetd`/`tuigreet` from Task 3.
- Produces: greetd active, using system user `_greetd`, with a `Conflicts=getty@tty1.service` drop-in (NOT a blanket getty mask). Login → `tuigreet --cmd sway`.

- [ ] **Step 1: Confirm `_greetd` exists (packaging-provided) and read its identity**

Run: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'getent passwd _greetd'`
Expected: a line like `_greetd:x:NNN:NNN::/var/lib/greetd:/usr/sbin/nologin`. If absent, the role must create it as a system user; if present (expected on Ubuntu), the role must NOT recreate it. Note which case applies for Step 2.

- [ ] **Step 2: Write the greetd config template**

`ansible/roles/greetd/templates/config.toml.j2`:
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd sway"
user = "_greetd"
```

- [ ] **Step 3: Write the getty conflict drop-in**

`ansible/roles/greetd/files/getty-conflict.conf`:
```ini
[Unit]
Conflicts=getty@tty1.service
After=getty@tty1.service
```

- [ ] **Step 4: Write tasks**

`ansible/roles/greetd/tasks/main.yml`:
```yaml
---
- name: Ensure _greetd system user exists
  become: true
  ansible.builtin.user:
    name: _greetd
    system: true
    create_home: false
    home: /var/lib/greetd
    shell: /usr/sbin/nologin

- name: Write greetd config
  become: true
  ansible.builtin.template:
    src: config.toml.j2
    dest: /etc/greetd/config.toml
    owner: root
    group: root
    mode: '0644'
  notify: Restart greetd

- name: Create greetd systemd drop-in dir
  become: true
  ansible.builtin.file:
    path: /etc/systemd/system/greetd.service.d
    state: directory
    mode: '0755'

- name: Install getty@tty1 conflict drop-in
  become: true
  ansible.builtin.copy:
    src: getty-conflict.conf
    dest: /etc/systemd/system/greetd.service.d/getty-conflict.conf
    mode: '0644'
  notify:
    - Reload systemd
    - Restart greetd

- name: Ensure getty@tty1 is not masked (superseded by declarative Conflicts=)
  become: true
  ansible.builtin.systemd:
    name: getty@tty1.service
    masked: false

- name: Enable greetd
  become: true
  ansible.builtin.systemd:
    name: greetd
    enabled: true
    state: started
```

- [ ] **Step 5: Write handlers**

`ansible/roles/greetd/handlers/main.yml`:
```yaml
---
- name: Reload systemd
  become: true
  ansible.builtin.systemd:
    daemon_reload: true

- name: Restart greetd
  become: true
  ansible.builtin.systemd:
    name: greetd
    state: restarted
```

- [ ] **Step 6: Add role to the Sway base play (after packages-base)**

In `ansible/playbook-sway-base.yml`, the Sway base play `roles:` becomes `[packages-base, greetd]`.

- [ ] **Step 7: Run and verify**

Run the playbook, then:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'systemctl is-active greetd; systemctl is-enabled getty@tty1.service 2>&1; grep -A2 default_session /etc/greetd/config.toml; systemctl cat greetd | grep -A2 getty-conflict || systemctl show greetd -p Conflicts'
```
Expected: greetd `active`; `getty@tty1` NOT `masked` (may be `static`/`disabled`); config shows `user = "_greetd"`; Conflicts includes `getty@tty1.service`.

- [ ] **Step 8: Verify idempotency**

Run the playbook again; expected `changed=0`.

- [ ] **Step 9: Commit**

```bash
git add ansible/roles/greetd ansible/playbook-sway-base.yml
git commit -m "feat(ansible): greetd role — _greetd user + getty Conflicts drop-in"
```

---

## Task 5: `sway-minimal` role

**Files:**
- Create: `ansible/roles/sway-minimal/files/config.d/{variables,keymaps,appearance,inputs,custom-keymap}.conf`
- Create: `ansible/roles/sway-minimal/files/modes.d/resize.conf`
- Create: `ansible/roles/sway-minimal/templates/config.j2`
- Create: `ansible/roles/sway-minimal/tasks/main.yml`
- Modify: `ansible/playbook-sway-base.yml`

**Interfaces:**
- Consumes: `sway`/`lxpolkit` from Task 3.
- Produces: a self-contained `~/.config/sway/` (plain files, no repo dependency) matching phase 1's six-fragment config. Playbook 2's `stow` role later replaces these with symlinks.

- [ ] **Step 1: Copy the six fragment files into the role verbatim from the repo**

The role embeds copies (NOT symlinks, NOT git). Copy from the control-node repo:
```bash
mkdir -p ansible/roles/sway-minimal/files/config.d ansible/roles/sway-minimal/files/modes.d
for f in variables keymaps appearance inputs custom-keymap; do cp stow/sway/.config/sway/config.d/$f.conf ansible/roles/sway-minimal/files/config.d/$f.conf; done
cp stow/sway/.config/sway/modes.d/resize.conf ansible/roles/sway-minimal/files/modes.d/resize.conf
```

- [ ] **Step 2: Write the minimal top-level config template**

`ansible/roles/sway-minimal/templates/config.j2` (byte-identical intent to phase 1's hand-written config):
```
set $mod Mod4

include $HOME/.config/sway/config.d/variables.conf
include $HOME/.config/sway/config.d/keymaps.conf
include $HOME/.config/sway/config.d/appearance.conf
include $HOME/.config/sway/config.d/inputs.conf
include $HOME/.config/sway/config.d/custom-keymap.conf
include $HOME/.config/sway/modes.d/*.conf

exec lxpolkit
```

- [ ] **Step 3: Write tasks**

`ansible/roles/sway-minimal/tasks/main.yml`:
```yaml
---
- name: Create sway config directories
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.config/sway/{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - config.d
    - modes.d

- name: Install portable config.d fragments
  ansible.builtin.copy:
    src: "config.d/{{ item }}.conf"
    dest: "{{ ansible_env.HOME }}/.config/sway/config.d/{{ item }}.conf"
    mode: '0644'
  loop:
    - variables
    - keymaps
    - appearance
    - inputs
    - custom-keymap

- name: Install resize mode fragment
  ansible.builtin.copy:
    src: modes.d/resize.conf
    dest: "{{ ansible_env.HOME }}/.config/sway/modes.d/resize.conf"
    mode: '0644'

- name: Install minimal top-level sway config
  ansible.builtin.template:
    src: config.j2
    dest: "{{ ansible_env.HOME }}/.config/sway/config"
    mode: '0644'
```

- [ ] **Step 4: Add role to the Sway base play (last)**

`roles:` becomes `[packages-base, greetd, sway-minimal]`.

- [ ] **Step 5: Run and validate config**

Run the playbook, then:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'export WLR_BACKENDS=headless; sway -c ~/.config/sway/config -C; echo "EXIT:$?"; diff <(cat ~/.config/sway/config.d/keymaps.conf) <(cat ~/.dot/stow/sway/.config/sway/config.d/keymaps.conf) 2>/dev/null || echo "(no ~/.dot on box yet — expected pre-playbook-2)"'
```
Expected: `sway -C` exits 0 (renderer device warnings are fine, per phase 1).

- [ ] **Step 6: Verify idempotency**

Run the playbook again; expected `changed=0`.

- [ ] **Step 7: Commit**

```bash
git add ansible/roles/sway-minimal ansible/playbook-sway-base.yml
git commit -m "feat(ansible): sway-minimal role — self-contained six-fragment config"
```

---

## Task 6: Playbook 1 end-to-end verification (reboot + screenshot)

**Files:** none (verification only).

**Interfaces:**
- Consumes: Tasks 2–5 (full `playbook-sway-base.yml`).
- Produces: live proof that a full `playbook-sway-base.yml` run yields a working login→Sway session across a real reboot. This closes out playbook 1.

- [ ] **Step 1: Full clean run of playbook 1**

Run: `cd ansible && ansible-playbook playbook-sway-base.yml`
Expected: completes with no failed tasks.

- [ ] **Step 2: Reboot the KVM**

Run: `virsh reboot ubu` then wait ~45s (poll SSH: `until ssh -i ~/.ssh/dot_ansible_ed25519 -o ConnectTimeout=3 jan@192.168.124.68 true 2>/dev/null; do sleep 3; done`).

- [ ] **Step 3: Screenshot the greeter and view it**

Run: `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/p2-01-greeter.png`
Then Read the PNG. Expected: tuigreet's boxed "Authenticate into ubu" / "Username:" prompt (same as phase 1's `01-tuigreet.png`).

- [ ] **Step 4: Log in via virsh send-key**

```bash
for k in KEY_J KEY_A KEY_N; do virsh send-key ubu "$k"; sleep 0.2; done
virsh send-key ubu KEY_ENTER; sleep 1
for k in KEY_J KEY_A KEY_N; do virsh send-key ubu "$k"; sleep 0.2; done
virsh send-key ubu KEY_ENTER; sleep 4
```

- [ ] **Step 5: Verify sway is running and foot opens**

```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'pgrep -a -u jan sway'
virsh send-key ubu KEY_LEFTMETA KEY_ENTER; sleep 1
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'SWAYSOCK=$(find /run/user/$(id -u jan) -maxdepth 1 -name "sway-ipc*" | head -1) swaymsg -t get_tree' | grep -o '"app_id": "foot"'
```
Expected: a running `sway` process and `"app_id": "foot"` in the tree.

- [ ] **Step 6: Final screenshot and view**

Run: `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/p2-02-sway.png` and Read it. Expected: a Sway session (foot terminal visible or a compositor background).

- [ ] **Step 7: Commit a status note (docs only)**

No code changed. Append a one-line note to the spec's Testing section recording playbook-1 verification:
Edit `docs/superpowers/specs/2026-08-11-ansible-ubuntu-environment-design.md`, adding under "Testing / verification" a line: `- Playbook 1 verified end-to-end on KVM (reboot + tuigreet + foot) YYYY-MM-DD.` (use today's date).
```bash
git add docs/superpowers/specs/2026-08-11-ansible-ubuntu-environment-design.md
git commit -m "docs(ansible): record playbook-1 end-to-end verification"
```

---

## Task 7: Push `ubuntu` branch to origin (GATED — human confirmation required)

**Files:** none (git remote state).

**Interfaces:**
- Consumes: nothing.
- Produces: `origin/ubuntu` up to date, so Task 9's `stow` role can clone a meaningful tree. **This task pushes to shared remote state and MUST NOT run without explicit human confirmation** (see plan constraints / spec "Prerequisite" note).

- [ ] **Step 1: Confirm with the human before pushing**

STOP and ask the human partner: "Task 9 (stow) clones `git@github.com:zezav-cz/.dot.git` at branch `ubuntu` onto the KVM. That requires pushing the local `ubuntu` branch (with all phase-1/phase-2 commits) to origin. Push now?" Do not proceed without an explicit yes.

- [ ] **Step 2: Push (only after confirmation)**

```bash
git push origin ubuntu
```
Expected: push succeeds; `git rev-parse origin/ubuntu` equals local `ubuntu` HEAD.

- [ ] **Step 3: No commit** (git remote action only; nothing to commit locally).

---

## Task 8: `packages-full` role

**Files:**
- Create: `ansible/roles/packages-full/vars/main.yml`
- Create: `ansible/roles/packages-full/tasks/main.yml`
- Create: `ansible/roles/packages-full/README.md` (per-package resolution log)
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: key auth (Task 2), apt.
- Produces: the full desktop/CLI package set installed on the KVM. Splits into `apt`-installable names vs. specially-handled packages (documented in README).

- [ ] **Step 1: Research each Fedora package's Ubuntu equivalent against the real KVM**

For every entry in `installer/config.py:44-120`, run `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'apt-cache policy <candidate>'` to find the real apt name (or confirm absence). Record the mapping in `README.md`. Known-tricky ones and their required resolution (verify each, don't assume):
  - `git-delta` → apt `git-delta`; `bat` → apt `bat` (binary is `batcat` on Debian/Ubuntu); `fd`-style renames apply.
  - `code` (VS Code) → NOT in Ubuntu repos: add Microsoft's apt repo + key, then `code`. Document the repo/key steps.
  - `mise` → NOT in Ubuntu repos: add jdx's apt repo (`https://mise.jdx.dev/deb`) + key, then `mise`. (The control node uses COPR; Ubuntu uses their apt repo.)
  - `SwayNotificationCenter` → apt package is `sway-notification-center`.
  - `nwg-bar`, `nwg-displays`, `rofimoji` → check `apt-cache`; if absent, resolve via `pip`/`pipx` or drop with a documented reason.
  - `cliphist` → check apt; likely available as `cliphist`.
  - `prismlauncher` → check apt; if absent, document (PPA or drop).
  - `cockpit-*` (all), `pcp`, `python3-pcp`, `geoclue2`, `fuse-libs`, `nerd-fonts`, `openssh-askpass`, `ruby-devel`/`*-devel` build deps → map to Ubuntu names (`geoclue-2.0`, `fuse3`, `ruby-dev`, `zlib1g-dev`, `libssl-dev`, `libreadline-dev`, `libffi-dev`, `libyaml-dev`, `libsqlite3-dev`, `libpcap-dev`, `libusb-1.0-0-dev`, etc.); `nerd-fonts` is handled by the `fonts` role (Task 12) not apt; `cockpit-*` are optional server-admin extras — install the ones that exist in Ubuntu (`cockpit`, `cockpit-podman`, `cockpit-networkmanager`, `cockpit-storaged`, `cockpit-packagekit`) and document any dropped.

Record every decision (apt-name / repo-added / pipx / dropped+why) in `README.md`. This research is the substance of the task — the reviewer checks the README against the real box.

- [ ] **Step 2: Write vars with the resolved apt package list**

`ansible/roles/packages-full/vars/main.yml` — a `packages_full` list of confirmed apt names, plus a separate `packages_full_extra_repos` structure for the Microsoft/mise repos (key url, repo line, signed-by path). Example shape:
```yaml
---
packages_full_repos:
  - name: vscode
    key_url: https://packages.microsoft.com/keys/microsoft.asc
    keyring: /etc/apt/keyrings/microsoft.gpg
    repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    filename: vscode
  - name: mise
    key_url: https://mise.jdx.dev/gpg-key.pub
    keyring: /etc/apt/keyrings/mise.gpg
    repo: "deb [signed-by=/etc/apt/keyrings/mise.gpg arch=amd64] https://mise.jdx.dev/deb stable main"
    filename: mise
packages_full:
  - git
  - git-delta
  # ... every confirmed apt name from Step 1 ...
```
(Fill the list with the actual resolved names from Step 1 — no placeholders in the committed file.)

- [ ] **Step 3: Write tasks (add repos, then install)**

`ansible/roles/packages-full/tasks/main.yml`:
```yaml
---
- name: Ensure apt keyrings dir exists
  become: true
  ansible.builtin.file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'

- name: Add signing keys for extra repos
  become: true
  ansible.builtin.get_url:
    url: "{{ item.key_url }}"
    dest: "{{ item.keyring }}.asc"
    mode: '0644'
  loop: "{{ packages_full_repos }}"
  loop_control: { label: "{{ item.name }}" }

- name: Dearmor extra-repo keys
  become: true
  ansible.builtin.command:
    cmd: "gpg --batch --yes --dearmor -o {{ item.keyring }} {{ item.keyring }}.asc"
    creates: "{{ item.keyring }}"
  loop: "{{ packages_full_repos }}"
  loop_control: { label: "{{ item.name }}" }

- name: Add extra apt repositories
  become: true
  ansible.builtin.apt_repository:
    repo: "{{ item.repo }}"
    filename: "{{ item.filename }}"
    state: present
  loop: "{{ packages_full_repos }}"
  loop_control: { label: "{{ item.name }}" }

- name: Install full package set
  become: true
  ansible.builtin.apt:
    name: "{{ packages_full }}"
    state: present
    update_cache: true
```

- [ ] **Step 4: Add role to playbook-environment.yml (first role)**

Set the environment play's `roles:` to `[packages-full]`.

- [ ] **Step 5: Run and verify**

Run: `cd ansible && ansible-playbook playbook-environment.yml`
Then spot-check: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'command -v waybar swaync code mise batcat; dpkg -s sway-notification-center >/dev/null && echo swaync-ok'`
Expected: the key desktop binaries resolve; document any intentionally-dropped package.

- [ ] **Step 6: Verify idempotency**

Run the playbook again; expected `changed=0`.

- [ ] **Step 7: Commit**

```bash
git add ansible/roles/packages-full ansible/playbook-environment.yml
git commit -m "feat(ansible): packages-full role with Ubuntu package mapping"
```

---

## Task 9: `stow` role

**Files:**
- Create: `ansible/roles/stow/tasks/main.yml`
- Create: `ansible/roles/stow/vars/main.yml`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: Task 7 (`origin/ubuntu` pushed), `stow` binary (from `packages-full`).
- Produces: `~/.dot` cloned on the KVM via a read-only deploy key; all `STOW_PACKAGES`/`STOW_NO_FOLDING` stowed; lazy.nvim cloned. Replaces `sway-minimal`'s plain files with symlinks into `~/.dot`.

- [ ] **Step 1: Create the deploy key on the KVM and register it with GitHub**

The deploy key is generated ON the KVM (private key never leaves the box), pubkey added to the repo via `gh` from the control node. Role tasks handle key generation + ssh config; the `gh` registration is a control-node step done once:
```bash
# (role generates ~/.ssh/dot_deploy on the KVM in Step 3; then, from control node:)
PUB=$(ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'cat ~/.ssh/dot_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/.dot --title "kvm-ubu-$(date +%Y%m%d)" --read-only <<<"$PUB"
gh repo deploy-key list --repo zezav-cz/.dot
```
(Ordering note: run the role once up to key-generation, do this registration, then re-run so the clone succeeds. Document this two-phase bootstrap in the role tasks' comments.)

- [ ] **Step 2: Write vars**

`ansible/roles/stow/vars/main.yml`:
```yaml
---
stow_repo: "git@github.com:zezav-cz/.dot.git"
stow_version: ubuntu
stow_dest: "{{ ansible_env.HOME }}/.dot"
stow_packages:
  - git
  - mise
  - nvim
  - rofi
  - ssh-agent
  - sway
  - systemd
  - tmux
  - zsh
  - foot
  - k9s
  - nwg-displays
stow_no_folding:
  - my-scripts
  - pgcli
  - vscode
lazy_nvim_repo: "https://github.com/folke/lazy.nvim.git"
lazy_nvim_path: "{{ ansible_env.HOME }}/.local/share/nvim/lazy/lazy.nvim"
```

- [ ] **Step 3: Write tasks**

`ansible/roles/stow/tasks/main.yml`:
```yaml
---
- name: Generate read-only deploy key on the KVM
  ansible.builtin.openssh_keypair:
    path: "{{ ansible_env.HOME }}/.ssh/dot_deploy"
    type: ed25519
    comment: "dot-deploy@ubu"

- name: Configure ssh to use the deploy key for github.com
  ansible.builtin.blockinfile:
    path: "{{ ansible_env.HOME }}/.ssh/config"
    create: true
    mode: '0600'
    marker: "# {mark} ANSIBLE dot deploy key"
    block: |
      Host github.com
        IdentityFile ~/.ssh/dot_deploy
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new

- name: Clone/update the .dot repo
  ansible.builtin.git:
    repo: "{{ stow_repo }}"
    dest: "{{ stow_dest }}"
    version: "{{ stow_version }}"
    accept_hostkey: true
    update: true

- name: Back up a non-symlink ~/.zshrc
  ansible.builtin.command:
    cmd: "mv {{ ansible_env.HOME }}/.zshrc {{ ansible_env.HOME }}/.zshrc.bak.{{ ansible_date_time.epoch }}"
    removes: "{{ ansible_env.HOME }}/.zshrc"
  when: >
    (lookup('ansible.builtin.file', ansible_env.HOME + '/.zshrc', errors='ignore') is not none)
  # Guard: only move if it exists AND is a real file (not our symlink).
  # See Step 4 note on making this idempotent.

- name: Remove phase-1 plain sway config files so stow can symlink
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.config/sway"
    state: absent
  # sway-minimal wrote plain files here; stow needs a clean target to link into.
  # This is safe: the authoritative config now comes from the repo.

- name: Stow folded packages
  ansible.builtin.command:
    cmd: "stow -d {{ stow_dest }}/stow -t {{ ansible_env.HOME }} --restow {{ item }}"
  loop: "{{ stow_packages }}"
  register: stow_folded
  changed_when: "'LINK' in stow_folded.stderr or 'UNLINK' in stow_folded.stderr"

- name: Stow no-folding packages
  ansible.builtin.command:
    cmd: "stow -d {{ stow_dest }}/stow -t {{ ansible_env.HOME }} --no-folding --restow {{ item }}"
  loop: "{{ stow_no_folding }}"
  register: stow_nofold
  changed_when: "'LINK' in stow_nofold.stderr or 'UNLINK' in stow_nofold.stderr"

- name: Clone lazy.nvim
  ansible.builtin.git:
    repo: "{{ lazy_nvim_repo }}"
    dest: "{{ lazy_nvim_path }}"
    version: stable
    depth: 1
    update: false
```

- [ ] **Step 4: Make the `.zshrc` backup idempotent**

The `.zshrc` move must not fire on re-runs once zsh is stowed (the stowed `.zshrc` is a symlink, which is fine and must be left alone). Refine the backup task to only act when `~/.zshrc` exists AND is a regular file (not a symlink): use a `stat` task first:
```yaml
- name: Stat ~/.zshrc
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.zshrc"
  register: zshrc_stat

- name: Back up a non-symlink ~/.zshrc
  ansible.builtin.command:
    cmd: "mv {{ ansible_env.HOME }}/.zshrc {{ ansible_env.HOME }}/.zshrc.bak.{{ ansible_date_time.epoch }}"
  when: zshrc_stat.stat.exists and zshrc_stat.stat.isreg and not zshrc_stat.stat.islnk
```
Replace the Step-3 backup task with this two-task form.

- [ ] **Step 5: Two-phase run (clone bootstrap), then verify**

Run the playbook once (deploy key gets generated, clone fails — expected). Do the Step-1 `gh` registration. Re-run. Then verify:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'ls -la ~/.config/nvim ~/.config/sway/config ~/.zshrc | grep -- "->"; test -d ~/.dot && echo dot-ok; test -d ~/.local/share/nvim/lazy/lazy.nvim && echo lazy-ok'
```
Expected: `~/.config/nvim`, `~/.config/sway/config`, `~/.zshrc` are symlinks into `~/.dot/stow/...`; `dot-ok`; `lazy-ok`.

- [ ] **Step 6: Verify idempotency**

Run the playbook again; expected `changed=0` (no LINK/UNLINK, clone reports no change, lazy.nvim `update: false` no-ops).

- [ ] **Step 7: Commit**

```bash
git add ansible/roles/stow ansible/playbook-environment.yml
git commit -m "feat(ansible): stow role — deploy-key clone + full stow set"
```

---

## Task 10: `shell` role

**Files:**
- Create: `ansible/roles/shell/tasks/main.yml`
- Create: `ansible/roles/shell/vars/main.yml`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: `zsh` (from `packages-full`), git.
- Produces: oh-my-zsh + 3 plugins installed; `jan`'s default shell = zsh.

- [ ] **Step 1: Write vars**

`ansible/roles/shell/vars/main.yml`:
```yaml
---
omz_dir: "{{ ansible_env.HOME }}/.oh-my-zsh"
zsh_custom: "{{ ansible_env.HOME }}/.oh-my-zsh/custom"
zsh_plugins:
  zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
  zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
  zsh-completions: https://github.com/zsh-users/zsh-completions
```

- [ ] **Step 2: Write tasks**

`ansible/roles/shell/tasks/main.yml`:
```yaml
---
- name: Clone oh-my-zsh
  ansible.builtin.git:
    repo: https://github.com/ohmyzsh/ohmyzsh.git
    dest: "{{ omz_dir }}"
    depth: 1
    version: master
    update: false

- name: Clone zsh custom plugins
  ansible.builtin.git:
    repo: "{{ item.value }}"
    dest: "{{ zsh_custom }}/plugins/{{ item.key }}"
    depth: 1
    version: master
    update: false
  loop: "{{ zsh_plugins | dict2items }}"
  loop_control: { label: "{{ item.key }}" }

- name: Set jan's default shell to zsh
  become: true
  ansible.builtin.user:
    name: jan
    shell: /usr/bin/zsh
```

- [ ] **Step 3: Add role to playbook-environment.yml (after stow)**

`roles:` becomes `[packages-full, stow, shell]`.

- [ ] **Step 4: Run and verify**

Run the playbook, then:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'test -d ~/.oh-my-zsh && echo omz-ok; ls ~/.oh-my-zsh/custom/plugins; getent passwd jan | cut -d: -f7'
```
Expected: `omz-ok`; the three plugin dirs; shell `/usr/bin/zsh`.

- [ ] **Step 5: Verify idempotency**

Run again; expected `changed=0` (git tasks use `update: false`; user shell already set).

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/shell ansible/playbook-environment.yml
git commit -m "feat(ansible): shell role — oh-my-zsh + plugins + default shell"
```

---

## Task 11: `apps` role

**Files:**
- Create: `ansible/roles/apps/tasks/main.yml`
- Create: `ansible/roles/apps/vars/main.yml`
- Create: `ansible/roles/apps/templates/app.desktop.j2`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: `fuse3` (from `packages-full`), `gpg`.
- Produces: Obsidian, Headlamp, Signal AppImages in `~/.local/bin`, desktop entries in `~/.local/share/applications`, Signal GPG-verified; dunst masked.

- [ ] **Step 1: Write vars (mirrors `installer/config.py:241-270`)**

`ansible/roles/apps/vars/main.yml`:
```yaml
---
appimage_dir: "{{ ansible_env.HOME }}/.local/bin"
desktop_dir: "{{ ansible_env.HOME }}/.local/share/applications"
icon_dir: "{{ ansible_env.HOME }}/.local/share/icons"
apps:
  - name: obsidian
    display_name: Obsidian
    url: "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.10.6/Obsidian-1.10.6.AppImage"
    icon_url: "https://obsidian.md/images/obsidian-logo-gradient.svg"
    categories: "Office;"
    wm_class: obsidian
  - name: headlamp
    display_name: Headlamp
    url: "https://github.com/kubernetes-sigs/headlamp/releases/download/v0.43.0/Headlamp-0.43.0-linux-x64.AppImage"
    icon_url: "https://raw.githubusercontent.com/kubernetes-sigs/headlamp/main/docs/images/icon.png"
    categories: "Development;"
    wm_class: Headlamp
  - name: signal-desktop
    display_name: Signal
    url: "https://updates.signal.org/desktop/signal-desktop.AppImage"
    gpg_key_url: "https://updates.signal.org/static/desktop/appimage.asc"
    gpg_sig_url: "https://updates.signal.org/desktop/signal-desktop.AppImage.gpg"
    icon_url: "https://raw.githubusercontent.com/signalapp/Signal-Desktop/main/build/icons/png/1024x1024.png"
    categories: "Network;InstantMessaging;"
    wm_class: signal
```

- [ ] **Step 2: Write the desktop-entry template**

`ansible/roles/apps/templates/app.desktop.j2`:
```
[Desktop Entry]
Type=Application
Name={{ item.display_name }}
Exec={{ appimage_dir }}/{{ item.name }} %U
{% if item.icon_url is defined %}Icon={{ icon_dir }}/{{ item.name }}
{% endif %}Terminal=false
Categories={{ item.categories }}
{% if item.wm_class is defined %}StartupWMClass={{ item.wm_class }}
{% endif %}
```

- [ ] **Step 3: Write tasks (download → optional GPG verify → install → desktop entry → mask dunst)**

`ansible/roles/apps/tasks/main.yml`:
```yaml
---
- name: Ensure app directories exist
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - "{{ appimage_dir }}"
    - "{{ desktop_dir }}"
    - "{{ icon_dir }}"

- name: Download AppImages
  ansible.builtin.get_url:
    url: "{{ item.url }}"
    dest: "{{ appimage_dir }}/{{ item.name }}"
    mode: '0755'
  loop: "{{ apps }}"
  loop_control: { label: "{{ item.name }}" }

- name: Download app icons (cosmetic, never fatal)
  ansible.builtin.get_url:
    url: "{{ item.icon_url }}"
    dest: "{{ icon_dir }}/{{ item.name }}{{ item.icon_url | regex_search('\\.[a-zA-Z0-9]+$') | default('.png', true) }}"
    mode: '0644'
  loop: "{{ apps | selectattr('icon_url', 'defined') | list }}"
  loop_control: { label: "{{ item.name }}" }
  failed_when: false

- name: Install desktop entries
  ansible.builtin.template:
    src: app.desktop.j2
    dest: "{{ desktop_dir }}/{{ item.name }}.desktop"
    mode: '0644'
  loop: "{{ apps }}"
  loop_control: { label: "{{ item.name }}" }

- name: Mask dunst (prevents it replacing swaync)
  ansible.builtin.systemd:
    name: dunst.service
    masked: true
    scope: user
  failed_when: false
```

- [ ] **Step 4: Add explicit Signal GPG verification**

Insert three real tasks scoped to Signal (there is no generic gpg loop — Signal is the only GPG-verified app):
```yaml
- name: Download Signal signing key
  ansible.builtin.get_url:
    url: "https://updates.signal.org/static/desktop/appimage.asc"
    dest: /tmp/signal-key.asc
    mode: '0644'

- name: Download Signal signature
  ansible.builtin.get_url:
    url: "https://updates.signal.org/desktop/signal-desktop.AppImage.gpg"
    dest: /tmp/signal-desktop.AppImage.gpg
    mode: '0644'

- name: Verify Signal AppImage signature
  ansible.builtin.shell:
    cmd: >
      gpg --no-default-keyring --keyring /tmp/signal-verify.gpg --import /tmp/signal-key.asc &&
      gpgv --keyring /tmp/signal-verify.gpg /tmp/signal-desktop.AppImage.gpg {{ appimage_dir }}/signal-desktop
  changed_when: false
```
Place these BEFORE the "Install desktop entries" task and AFTER the AppImage download. (The download-icons and desktop-entry tasks stay.)

- [ ] **Step 5: Add role to playbook-environment.yml**

`roles:` becomes `[packages-full, stow, shell, apps]`.

- [ ] **Step 6: Run and verify**

Run the playbook, then:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'ls -la ~/.local/bin/{obsidian,headlamp,signal-desktop}; ls ~/.local/share/applications/*.desktop'
```
Expected: three executable AppImages; three `.desktop` files. The playbook run must show the Signal verify task succeeding (no failure).

- [ ] **Step 7: Verify idempotency**

Run again; expected `changed=0` (get_url skips existing files by checksum/size, templates unchanged, dunst already masked). If `get_url` re-reports changed for the self-updating Signal URL, add `force: false` (default) and confirm — document if Signal's unversioned URL cannot be made fully idempotent (acceptable, note it).

- [ ] **Step 8: Commit**

```bash
git add ansible/roles/apps ansible/playbook-environment.yml
git commit -m "feat(ansible): apps role — AppImages + Signal GPG verify + desktop entries"
```

---

## Task 12: `fonts` role

**Files:**
- Create: `ansible/roles/fonts/tasks/main.yml`
- Create: `ansible/roles/fonts/vars/main.yml`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: `unzip`/`fontconfig` (ensure in `packages-full`), `fc-cache`.
- Produces: Meslo Nerd Font + Font Awesome 6 extracted under `~/.local/share/fonts/`, font cache refreshed.

- [ ] **Step 1: Write vars (mirrors `installer/config.py:199-212`, `NERD_FONTS_VERSION=v3.4.0`)**

`ansible/roles/fonts/vars/main.yml`:
```yaml
---
fonts_dir: "{{ ansible_env.HOME }}/.local/share/fonts"
fonts:
  - name: Meslo Nerd Font
    url: "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip"
    extract_dir: nerd-fonts
  - name: Font Awesome 6 Console
    url: "https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip"
    extract_dir: fontawesome-6-console
```

- [ ] **Step 2: Write tasks**

`ansible/roles/fonts/tasks/main.yml`:
```yaml
---
- name: Ensure font extract dirs exist
  ansible.builtin.file:
    path: "{{ fonts_dir }}/{{ item.extract_dir }}"
    state: directory
    mode: '0755'
  loop: "{{ fonts }}"
  loop_control: { label: "{{ item.name }}" }

- name: Download and extract fonts
  ansible.builtin.unarchive:
    src: "{{ item.url }}"
    dest: "{{ fonts_dir }}/{{ item.extract_dir }}"
    remote_src: true
    creates: "{{ fonts_dir }}/{{ item.extract_dir }}/.extracted"
  loop: "{{ fonts }}"
  loop_control: { label: "{{ item.name }}" }
  register: font_extract

- name: Mark extracted fonts (idempotency sentinel)
  ansible.builtin.file:
    path: "{{ fonts_dir }}/{{ item.extract_dir }}/.extracted"
    state: touch
    mode: '0644'
  loop: "{{ fonts }}"
  loop_control: { label: "{{ item.name }}" }
  when: font_extract is changed

- name: Refresh font cache
  ansible.builtin.command: fc-cache -f
  when: font_extract is changed
  changed_when: font_extract is changed
```

- [ ] **Step 3: Add role to playbook-environment.yml**

`roles:` becomes `[packages-full, stow, shell, apps, fonts]`.

- [ ] **Step 4: Run and verify**

Run, then: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'ls ~/.local/share/fonts/nerd-fonts | head; fc-list | grep -i meslo | head -1'`
Expected: font files present; `fc-list` finds Meslo.

- [ ] **Step 5: Verify idempotency**

Run again; expected `changed=0` (the `.extracted` sentinel makes `unarchive` skip, so `fc-cache` doesn't fire).

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/fonts ansible/playbook-environment.yml
git commit -m "feat(ansible): fonts role — Nerd Font + Font Awesome"
```

---

## Task 13: `vnotes` role

**Files:**
- Create: `ansible/roles/vnotes/tasks/main.yml`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: the deploy key + github ssh config from the `stow` role (Task 9) — same `git@github.com` access path. **Note:** the deploy key registered in Task 9 is scoped to `zezav-cz/.dot` only. The vnotes repo (`zezav-cz/vnotes`) needs its own access. Resolve during implementation: either register a second deploy key on `zezav-cz/vnotes`, or (simpler) confirm whether `~/.ssh/dot_deploy` already has access. If a second key is needed, mirror Task 9's `gh repo deploy-key add --repo zezav-cz/vnotes` pattern and document it.
- Produces: `~/vnotes` cloned/updated.

- [ ] **Step 1: Resolve vnotes repo access**

From the control node: `gh repo deploy-key add /dev/stdin --repo zezav-cz/vnotes --title "kvm-ubu-vnotes-$(date +%Y%m%d)" --read-only <<<"$(ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'cat ~/.ssh/dot_deploy.pub')"` (a deploy key is per-repo, so vnotes needs its own registration of the same pubkey). Verify with `gh repo deploy-key list --repo zezav-cz/vnotes`.

- [ ] **Step 2: Write tasks**

`ansible/roles/vnotes/tasks/main.yml`:
```yaml
---
- name: Clone/update vnotes repo
  ansible.builtin.git:
    repo: "git@github.com:zezav-cz/vnotes.git"
    dest: "{{ ansible_env.HOME }}/vnotes"
    version: master
    accept_hostkey: true
    update: true
```

- [ ] **Step 3: Add role to playbook-environment.yml**

`roles:` becomes `[packages-full, stow, shell, apps, fonts, vnotes]`.

- [ ] **Step 4: Run and verify**

Run, then: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'test -d ~/vnotes/.git && echo vnotes-ok'`
Expected: `vnotes-ok`.

- [ ] **Step 5: Verify idempotency**

Run again; expected `changed=0` (clean checkout, no upstream changes).

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/vnotes ansible/playbook-environment.yml
git commit -m "feat(ansible): vnotes role"
```

---

## Task 14: `mcp` role

**Files:**
- Create: `ansible/roles/mcp/tasks/main.yml`
- Create: `ansible/roles/mcp/vars/main.yml`
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: nothing distro-specific.
- Produces: the 3 MCP servers merged into `~/.claude.json` (merge-only, never clobbering existing entries — mirrors `s08_mcp.py`).

- [ ] **Step 1: Write vars (mirrors `installer/config.py:319-336`)**

`ansible/roles/mcp/vars/main.yml`:
```yaml
---
mcp_servers:
  sequential-thinking:
    type: stdio
    command: npx
    args: ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    env: {}
  vnotes:
    type: stdio
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem", "{{ ansible_env.HOME }}/vnotes"]
    env: {}
  kubernetes-mcp-server:
    command: npx
    args: ["-y", "kubernetes-mcp-server@latest", "--read-only"]
```

- [ ] **Step 2: Write tasks (merge-only, atomic)**

`ansible/roles/mcp/tasks/main.yml`:
```yaml
---
- name: Read existing ~/.claude.json (if any)
  ansible.builtin.slurp:
    src: "{{ ansible_env.HOME }}/.claude.json"
  register: claude_raw
  failed_when: false

- name: Parse existing config
  ansible.builtin.set_fact:
    claude_config: "{{ (claude_raw.content | b64decode | from_json) if (claude_raw.content is defined) else {} }}"

- name: Merge MCP servers (existing entries win — never clobber)
  ansible.builtin.set_fact:
    claude_merged: >-
      {{ claude_config | combine({'mcpServers':
         (mcp_servers | combine(claude_config.mcpServers | default({}))) }) }}

- name: Write merged config atomically
  ansible.builtin.copy:
    content: "{{ claude_merged | to_nice_json(indent=2) }}\n"
    dest: "{{ ansible_env.HOME }}/.claude.json"
    mode: '0644'
```

- [ ] **Step 3: Add role to playbook-environment.yml (last)**

`roles:` becomes `[packages-full, stow, shell, apps, fonts, vnotes, mcp]`.

- [ ] **Step 4: Run and verify**

Run, then: `ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'python3 -c "import json;d=json.load(open(\"$HOME/.claude.json\"));print(sorted(d[\"mcpServers\"]))"'`
Expected: includes `kubernetes-mcp-server`, `sequential-thinking`, `vnotes`.

- [ ] **Step 5: Verify idempotency (the important one — merge must be stable)**

Run the playbook again; expected `changed=0` on the "Write merged config" task. If it reports changed, the merge/serialization isn't stable (e.g. key ordering) — fix so a second run is a byte-identical no-op. This is the correctness crux of a merge-only task.

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/mcp ansible/playbook-environment.yml
git commit -m "feat(ansible): mcp role — merge servers into ~/.claude.json"
```

---

## Task 15: `sway-portability` role (+ repo config changes)

**Files:**
- Create: `stow/sway/.config/sway/config.d/{90-bar,60-bindings-brightness,60-bindings-media,60-bindings-volume,60-bindings-screenshot,90-swayidle,95-xdg-desktop-autostart,95-xdg-user-dirs}.conf` (repo-owned ports of Fedora's fragments)
- Modify: `stow/sway/.config/sway/config` (portable layered include)
- Modify: `stow/sway/.config/sway/config.d/variables.conf` (fix `$volume_limit` comment)
- Create: `ansible/roles/sway-portability/tasks/main.yml` (verification-only role; the real fix is the repo files, delivered via the already-run `stow` role)
- Modify: `ansible/playbook-environment.yml`

**Interfaces:**
- Consumes: the `stow` role (Task 9) — these new `stow/sway/` files reach the KVM through the existing sway stow package. This role is a thin verification wrapper; the substance is the repo files.
- Produces: waybar (and the other OS-level fragments) actually activate from the real config on Ubuntu; `layered-include` is replaced with a portable equivalent that works on both Ubuntu and Fedora; `$volume_limit` no longer references a nonexistent path.

- [ ] **Step 1: Read Fedora's real fragments on the control node**

Read each of these on THIS machine and port their essential content into the matching repo files (same basenames):
```bash
for f in 90-bar 60-bindings-brightness 60-bindings-media 60-bindings-volume 60-bindings-screenshot 90-swayidle 95-xdg-desktop-autostart 95-xdg-user-dirs; do echo "=== $f ==="; cat /usr/share/sway/config.d/$f.conf; done
```
Port each into `stow/sway/.config/sway/config.d/<same-name>.conf`. Keep them distro-agnostic (they already are — they reference `waybar`, `brightnessctl`/`light`, `wpctl`/`pactl`, `grim`/`slurp`, `swayidle`, `xdg-user-dirs-update`). If a fragment references a Fedora-only binary, adapt to the Ubuntu-available one and note it in the file. The critical one is `90-bar.conf` — it must contain the `bar { swaybar_command waybar }` block, because nothing else starts waybar.

- [ ] **Step 2: Replace the `layered-include` line with a portable equivalent**

In `stow/sway/.config/sway/config`, replace the final line:
```
include '$(/usr/libexec/sway/layered-include "/usr/share/sway/config.d/*.conf" "/etc/sway/config.d/*.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d/*.conf")'
```
with a shell-conditional include that uses layered-include when present (Fedora) and falls back to plain layered includes elsewhere (Ubuntu):
```
# Portable layered config include. On Fedora, /usr/libexec/sway/layered-include
# dedups fragments by basename (user copies override system ones). On distros
# without it (Ubuntu), fall back to plain includes of the system + user layers.
include '$([ -x /usr/libexec/sway/layered-include ] && /usr/libexec/sway/layered-include "/usr/share/sway/config.d/*.conf" "/etc/sway/config.d/*.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d/*.conf" || printf "%s\n" /etc/sway/config.d/*.conf "${XDG_CONFIG_HOME:-$HOME/.config}"/sway/config.d/*.conf)'
```
This keeps Fedora behavior byte-identical and makes Ubuntu load `/etc/sway/config.d/*.conf` (which includes Ubuntu's `50-systemd-user.conf` that imports the graphical-session env into the systemd user manager — resolving phase 1's "systemd user session env not imported" finding) plus the repo's own `config.d/*.conf` fragments.

- [ ] **Step 3: Fix the orphaned `$volume_limit` comment**

In `stow/sway/.config/sway/config.d/variables.conf`, the comment on `set $volume_limit 150` says it's "consumed by /usr/share/sway/config.d/60-bindings-volume.conf". Update it to point at the now repo-owned fragment:
```
# Max volume (%) for XF86AudioRaiseVolume; consumed by
# config.d/60-bindings-volume.conf (repo-owned, portable across distros).
set $volume_limit 150
```

- [ ] **Step 4: Write the verification-only role**

`ansible/roles/sway-portability/tasks/main.yml` (the stow role already delivered the files; this role just asserts they landed and validates):
```yaml
---
- name: Assert repo-owned bar fragment is present via stow
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.config/sway/config.d/90-bar.conf"
  register: bar_frag

- name: Fail if bar fragment missing
  ansible.builtin.assert:
    that: bar_frag.stat.exists and bar_frag.stat.islnk
    fail_msg: "90-bar.conf not stowed — waybar will not start"

- name: Validate the full real sway config parses
  ansible.builtin.command:
    cmd: sway -c {{ ansible_env.HOME }}/.config/sway/config -C
  environment:
    WLR_BACKENDS: headless
  changed_when: false
  register: sway_validate
  failed_when: sway_validate.rc != 0
```

- [ ] **Step 5: Add role to playbook-environment.yml (last, after mcp)**

`roles:` becomes `[packages-full, stow, shell, apps, fonts, vnotes, mcp, sway-portability]`. Since these repo files are delivered by the `stow` role's clone, push the branch (Task 7 already done) and ensure the `stow` role re-clones the updated `ubuntu` branch: the `git` module with `update: true` pulls the new commits, so run order (stow before sway-portability) is correct.

- [ ] **Step 6: Push repo changes, re-run, verify**

Commit the repo-file changes first (Step 7 below), push to `origin/ubuntu`, then run `cd ansible && ansible-playbook playbook-environment.yml`. Verify:
```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'ls -la ~/.config/sway/config.d/90-bar.conf; export WLR_BACKENDS=headless; sway -c ~/.config/sway/config -C; echo EXIT:$?'
```
Expected: `90-bar.conf` is a symlink into `~/.dot`; `sway -C` exits 0.

- [ ] **Step 7: Commit (repo files first, then role)**

```bash
git add stow/sway/.config/sway/config stow/sway/.config/sway/config.d/
git commit -m "feat(sway): portable layered-include + repo-owned OS fragments"
git add ansible/roles/sway-portability ansible/playbook-environment.yml
git commit -m "feat(ansible): sway-portability verification role"
git push origin ubuntu
```

---

## Task 16: Playbook 2 full-desktop verification (reboot + waybar/swaync on screen)

**Files:** none (verification only).

**Interfaces:**
- Consumes: Tasks 8–15 (full `playbook-environment.yml`).
- Produces: live proof the *real* desktop renders on Ubuntu — specifically waybar and swaync appear, which phase 1 never tested. Closes phase 2.

- [ ] **Step 1: Idempotency of the whole environment playbook**

Run `cd ansible && ansible-playbook playbook-environment.yml` twice. The second run's recap must show `changed=0` across all roles. Any role reporting `changed` on the second run is a defect — fix before proceeding.

- [ ] **Step 2: Reboot and log in**

`virsh reboot ubu`; wait for SSH; then the greeter screenshot + send-key login sequence from Task 6 Steps 3–4. Screenshot to `/tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/p2-03-greeter.png` and Read it (confirm tuigreet still renders after the full environment install).

- [ ] **Step 3: Verify waybar and swaync are actually running**

```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'pgrep -a -u jan waybar; pgrep -a -u jan swaync; systemctl --user is-active graphical-session.target'
```
Expected: a running `waybar` process (proves `90-bar.conf` activated it), a running `swaync`, and `graphical-session.target` is `active` (proves the systemd user-session env import via `/etc/sway/config.d`, i.e. phase 1's open finding is resolved).

- [ ] **Step 4: Visual confirmation and view**

Run `virsh screenshot ubu /tmp/claude-1000/-home-jan--dot/b0006648-2f82-491c-afc0-38973bea776c/scratchpad/p2-04-desktop.png` and Read it. Expected: a Sway desktop with a waybar bar visible on screen (not a bare compositor background).

- [ ] **Step 5: Verify stow symlinks resolve into the repo**

```bash
ssh -i ~/.ssh/dot_ansible_ed25519 jan@192.168.124.68 'for p in ~/.config/nvim ~/.config/foot ~/.config/sway/config ~/.tmux.conf; do readlink -f "$p" | grep -q "/.dot/" && echo "OK $p" || echo "NOT-STOWED $p"; done'
```
Expected: `OK` for the spot-checked paths (they resolve into `~/.dot/stow/...`).

- [ ] **Step 6: Record phase-2 completion in the spec and commit**

Edit `docs/superpowers/specs/2026-08-11-ansible-ubuntu-environment-design.md`: change `**Status:** Approved` to `**Status:** Phase 2 complete — verified on KVM 192.168.124.68 YYYY-MM-DD` (today's date), and add a Testing line noting waybar/swaync confirmed on-screen.
```bash
git add docs/superpowers/specs/2026-08-11-ansible-ubuntu-environment-design.md
git commit -m "docs(ansible): mark phase 2 complete — full desktop verified on KVM"
git push origin ubuntu
```
