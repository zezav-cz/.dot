# Ansible — Ubuntu Sway environment

Provision a **bare Ubuntu 26.04 Server** into the full Sway desktop
(greetd + tuigreet login, Sway, waybar, all the dotfiles, apps, fonts,
CLI tooling) over SSH from your workstation, by IP. Two playbooks:

| Playbook | What it does | Runs on |
|---|---|---|
| `playbook-sway-base.yml` | Bare server → bootable Sway + login screen. Self-contained (no repo checkout on the target). | A fresh server |
| `playbook-environment.yml` | Full parity with the Fedora `install.py`: clone `.dot`, stow every config, oh-my-zsh, AppImages, fonts, vnotes, MCP servers, the portability fixes. | After the base playbook |

Run the base playbook once, then the environment playbook. Both are
idempotent — re-running a completed playbook reports `changed=0`.

## Prerequisites (control node = your workstation)

- **mise** (provides `ansible-core` + `ansible-lint`, pinned in the repo's
  root `mise.toml`). From the repo root: `mise install`.
- **Ansible collections**: from this `ansible/` directory —
  `mise exec -- ansible-galaxy collection install -r requirements.yml`
- **A dedicated SSH keypair** the playbooks use to reach the target.
  Create it once if you don't have it:
  ```bash
  test -f ~/.ssh/dot_ansible_ed25519 || \
    ssh-keygen -t ed25519 -N '' -C 'ansible@dot' -f ~/.ssh/dot_ansible_ed25519
  ```
- **`gh`** (GitHub CLI), authenticated with access to `zezav-cz/.dot` and
  `zezav-cz/vnotes` — needed once to register the target's read-only deploy
  keys (`gh auth status` to check).
- **`sshpass`** — only if the target doesn't have your key yet and the very
  first connection must use a password (see step 1).
- The target: a reachable Ubuntu 26.04 Server with `openssh-server` running,
  and a user with `sudo` rights (examples below use `jan`).

## Point it at your target

Edit `inventory.yml` — set `ansible_host` to the target IP (and the user if
different):

```yaml
sway_hosts:
  hosts:
    ubu:
      ansible_host: 203.0.113.10      # <-- target server IP
      ansible_user: jan               # <-- login/sudo user on the target
      ansible_ssh_private_key_file: ~/.ssh/dot_ansible_ed25519
```

Or override at the command line without editing the file, by adding
`-e ansible_host=203.0.113.10 -e ansible_user=jan` to any command below.

Everything below is run from this `ansible/` directory (so `ansible.cfg`
and the inventory are picked up). `mise exec --` puts the pinned
`ansible-playbook` on PATH.

## Step 1 — base: `playbook-sway-base.yml`

```bash
mise exec -- ansible-playbook playbook-sway-base.yml \
  -e ansible_become_password='<sudo-password>'
```

- **`-e ansible_become_password=...` is required.** A fresh server needs a
  password for `sudo`, and Ansible needs it for every privileged task.
  (Prefer `--ask-become-pass` to be prompted instead of putting the
  password on the command line / in shell history.)
- **First connection auth.** The inventory authenticates with
  `~/.ssh/dot_ansible_ed25519`. If that key isn't in the target user's
  `authorized_keys` yet, the first run can't connect by key — add password
  auth for that one run:
  ```bash
  mise exec -- ansible-playbook playbook-sway-base.yml \
    -e ansible_become_password='<sudo-password>' \
    --ask-pass          # prompts for the SSH login password (needs sshpass)
  ```
  `bootstrap-auth` installs the dedicated key during this run, so every
  later run (including the environment playbook) uses key auth with no
  `--ask-pass`.

What the base playbook does, in order: **bootstrap-auth** (installs the SSH
key, and — see note below — switches the system to classic `sudo`, and
disables empty-password SSH) → **packages-base** (sway, foot, greetd,
tuigreet, xwayland, lxpolkit) → **greetd** (login screen on tty1) →
**sway-minimal** (a self-contained Sway config).

Reboot the server and you should land on the tuigreet login screen; logging
in starts Sway.

> **Ubuntu 26.04 / sudo-rs note.** 26.04 ships `sudo-rs` as the default
> `sudo`, whose password prompt is incompatible with Ansible's `become`
> (runs hang "waiting for privilege escalation prompt"). `bootstrap-auth`
> automatically switches the default to classic `sudo` via
> `update-alternatives` on its first pass — this is why the base playbook
> must run first and must be given the become password.

## Step 2 — environment: `playbook-environment.yml`

The environment playbook clones the private `.dot` (and `vnotes`) repos onto
the target using **per-target read-only deploy keys**. Those keys are
generated on the target, so the first run stops at the clone until you
register them. This is a one-time, two-phase bootstrap per fresh machine.

**2a. First run — generates the deploy key, then fails at the `.dot` clone
(expected):**

```bash
mise exec -- ansible-playbook playbook-environment.yml \
  -e ansible_become_password='<sudo-password>'
```

**2b. Register the target's new deploy key on the `.dot` repo:**

```bash
PUB=$(ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<target-ip> 'cat ~/.ssh/dot_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/.dot --title "$(hostname)-$(date +%F)" <<<"$PUB"
```

**2c. Re-run.** It now clones `.dot`, stows everything, and continues until
it stops again at the **vnotes** clone (a separate repo needs its own deploy
key). Register that one too, then re-run a final time:

```bash
VPUB=$(ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<target-ip> 'cat ~/.ssh/vnotes_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/vnotes --title "vnotes-$(date +%F)" <<<"$VPUB"

mise exec -- ansible-playbook playbook-environment.yml \
  -e ansible_become_password='<sudo-password>'
```

The run now completes end-to-end. Reboot the target for the full waybar
desktop.

> **Which branch gets cloned.** The stow role clones the branch named by
> `stow_version` (default `ubuntu`). To provision from a different branch
> — e.g. while a feature branch is still in review — add
> `-e stow_version=<branch>` to the environment-playbook commands. The
> branch must be pushed to `origin` first.

## Step 3 — verify

```bash
# from the control node, key auth now works
ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<target-ip> '
  pgrep -u $USER -x sway waybar swaync >/dev/null && echo "desktop up"
  systemctl is-active greetd
  git -C ~/.dot status --porcelain | head        # should be empty (clean)
  zsh -ic "command -v bat fd rg rofi lazygit"     # tools resolve
'
```

Re-running either playbook should report `changed=0` (idempotent).

## Optional — dev CLI tools (mise-managed)

Like the Fedora `install.py`, the playbooks do **not** run `mise install` on
the target, so mise-managed dev tools (`kubectl`, `helm`, `k9s`, `yq`, `gh`,
…) are absent until you pull them. On the target, after logging in:

```bash
mise install
```

## Quick reference

| Command (run in `ansible/`) | Purpose |
|---|---|
| `mise exec -- ansible-galaxy collection install -r requirements.yml` | Install required collections (once) |
| `mise exec -- ansible-playbook playbook-sway-base.yml -e ansible_become_password=…` | Bare server → Sway + login |
| `mise exec -- ansible-playbook playbook-environment.yml -e ansible_become_password=…` | Full desktop/dotfiles parity |
| `mise exec -- ansible-lint` | Lint all roles/playbooks |
| `mise exec -- ansible-playbook <pb> --syntax-check` | Syntax-check a playbook |
| `mise exec -- ansible-playbook <pb> --check --diff …` | Dry-run (no changes) |

## Layout

```
ansible/
├── ansible.cfg          # inventory path, roles path, YAML output
├── inventory.yml        # target host(s): IP, user, key
├── requirements.yml     # Galaxy collections (ansible.posix, community.*)
├── playbook-sway-base.yml
├── playbook-environment.yml
└── roles/
    ├── bootstrap-auth/  # SSH key, sudo-rs→classic, close empty-pw SSH
    ├── packages-base/   # sway, foot, greetd, tuigreet, xwayland, lxpolkit
    ├── greetd/          # tuigreet login on tty1 (_greetd user, getty drop-in)
    ├── sway-minimal/    # self-contained Sway config (no repo needed)
    ├── packages-full/   # full apt set + vscode/mise/tailscale repos + shims
    ├── stow/            # deploy-key clone of .dot + GNU stow the dotfiles
    ├── shell/           # oh-my-zsh + plugins + default shell
    ├── apps/            # Obsidian/Headlamp/Signal AppImages + desktop entries
    ├── fonts/           # Nerd Font + Font Awesome
    ├── vnotes/          # clone the notes repo
    ├── mcp/             # register Claude Code MCP servers
    └── sway-portability/# repo-owned OS fragments (waybar bar, bindings, …)
```

See `../docs/superpowers/specs/2026-08-11-ansible-ubuntu-environment-design.md`
for the design rationale and the portability findings behind these roles.
