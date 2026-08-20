# Install Ubuntu Sway on a server

Prereqs on the target: SSH key access + `NOPASSWD` sudo for `<user>`, and a
GitHub-authorised SSH key/agent (for cloning the private `vnotes` repo).
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

`vnotes` is a private repo. Clone it by forwarding your workstation's
ssh-agent (which must have a key with access to `zezav-cz/vnotes`):

```bash
ansible-playbook -i '<IP>,' -u <user> --ssh-extra-args='-o ForwardAgent=yes' playbook-environment.yml
```

Or skip it: `--skip-tags vnotes`.

Clone a non-default branch: add `-e stow_version=<branch>`.
