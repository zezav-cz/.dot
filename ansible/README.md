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
# full desktop + dotfiles (clones zezav-cz/.dot by default)
ansible-playbook -i '<IP>,' -u <user> playbook-environment.yml

# or with a custom GitHub user / .dot fork:
ansible-playbook -i '<IP>,' -u <user> -e github_user=<github_username> playbook-environment.yml
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

## Using a different GitHub user (fork / personal account)

All repos (`.dot`, `vnotes`, dev-repos) are cloned under a configurable GitHub username.
Default is `zezav-cz`. To use your own fork or GitHub account:

```bash
# Example: use your own fork at github.com/john-doe/dot
ansible-playbook -i '<IP>,' -u <user> -e github_user=john-doe playbook-environment.yml
```

This sets:
- `.dot` repo: `john-doe/.dot`
- `vnotes` repo: `john-doe/vnotes` (skippable with `--skip-tags vnotes`)
- dev repos under `~/dev/john/` (prefix derived from `john-doe`)
