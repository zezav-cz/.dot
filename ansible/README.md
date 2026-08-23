# Install Ubuntu Sway on a server

Prereqs on the target: SSH key access + `NOPASSWD` sudo for `<user>`, and a
GitHub-authorised SSH key/agent — all `zezav-cz` repos (`.dot`, `vnotes`)
are cloned over SSH only (the `git-clone` role; no HTTPS fallback).
Run from this `ansible/` directory. Pass the target IP with `-i '<IP>,'` (trailing comma).

```bash
ansible-galaxy collection install -r requirements.yml
```

```bash
# base: bare server -> Sway + login screen
ansible-playbook -i '<IP>,' -u <user> playbook-sway-base.yml
```

```bash
# full desktop + dotfiles
ansible-playbook -i '<IP>,' -u <user> playbook-environment.yml
```

```bash
# reboot into the desktop, then pull mise-managed dev tools
ssh <user>@<IP> 'sudo reboot'
ssh <user>@<IP> 'mise install'
```

When installing from another machine, the target has no GitHub key of its
own — forward your workstation's ssh-agent (which must hold a key with
access to the `zezav-cz` repos). Running locally, the local ssh-agent is
used directly; if no key is reachable, the play fails fast with
instructions.

```bash
ansible-playbook -i '<IP>,' -u <user> --ssh-extra-args='-o ForwardAgent=yes' playbook-environment.yml
```

`vnotes` is private and can be skipped: `--skip-tags vnotes`. The working
repos under `~/dev/zezav/` (role `dev-repos`, some private) can likewise be
skipped: `--skip-tags dev-repos`. Existing checkouts there are never
updated by re-runs.

Clone a non-default branch: add `-e stow_version=<branch>`.
