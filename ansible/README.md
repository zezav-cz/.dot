# Install Ubuntu Sway on a server

Prereqs on the target: SSH key access + `NOPASSWD` sudo for `<user>`.
Run from this `ansible/` directory. Pass the target IP with `-i '<IP>,'` (trailing comma).

```bash
ansible-galaxy collection install -r requirements.yml
```

```bash
# base: bare server -> Sway + login screen
ansible-playbook -i '<IP>,' -u <user> playbook-sway-base.yml
```

```bash
# full desktop + dotfiles (deploy keys are two-phase)

ansible-playbook -i '<IP>,' -u <user> playbook-environment.yml   # stops at .dot clone

PUB=$(ssh <user>@<IP> 'cat ~/.ssh/dot_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/.dot --title "$(date +%F)" <<<"$PUB"

ansible-playbook -i '<IP>,' -u <user> playbook-environment.yml   # stops at vnotes clone

VPUB=$(ssh <user>@<IP> 'cat ~/.ssh/vnotes_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/vnotes --title "vnotes-$(date +%F)" <<<"$VPUB"

ansible-playbook -i '<IP>,' -u <user> playbook-environment.yml   # completes
```

```bash
# reboot into the desktop, then pull mise-managed dev tools
ssh <user>@<IP> 'sudo reboot'
ssh <user>@<IP> 'mise install'
```

Clone a non-default branch: add `-e stow_version=<branch>`.
