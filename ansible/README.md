# Ansible — install Ubuntu Sway on a server by IP

Run everything from this `ansible/` directory.

```bash
# 0. one-time setup
mise install
mise exec -- ansible-galaxy collection install -r requirements.yml
test -f ~/.ssh/dot_ansible_ed25519 || ssh-keygen -t ed25519 -N '' -f ~/.ssh/dot_ansible_ed25519

# set the target IP + user
$EDITOR inventory.yml        # ansible_host: <IP>, ansible_user: <user>
```

```bash
# 1. base: bare server -> Sway + login screen
mise exec -- ansible-playbook playbook-sway-base.yml \
  -e ansible_become_password='<sudo-pw>' --ask-pass
# (drop --ask-pass on later runs; the key is installed now)
```

```bash
# 2. environment: full desktop + dotfiles

# 2a. first run — generates deploy key, stops at the .dot clone (expected)
mise exec -- ansible-playbook playbook-environment.yml -e ansible_become_password='<sudo-pw>'

# 2b. register the .dot deploy key
PUB=$(ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<IP> 'cat ~/.ssh/dot_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/.dot --title "$(date +%F)" <<<"$PUB"

# 2c. re-run — stops at the vnotes clone; register that key too
mise exec -- ansible-playbook playbook-environment.yml -e ansible_become_password='<sudo-pw>'
VPUB=$(ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<IP> 'cat ~/.ssh/vnotes_deploy.pub')
gh repo deploy-key add /dev/stdin --repo zezav-cz/vnotes --title "vnotes-$(date +%F)" <<<"$VPUB"

# 2d. final run — completes
mise exec -- ansible-playbook playbook-environment.yml -e ansible_become_password='<sudo-pw>'
```

```bash
# 3. reboot the target, then optionally pull mise-managed dev tools
ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<IP> 'sudo reboot'
ssh -i ~/.ssh/dot_ansible_ed25519 <user>@<IP> 'mise install'
```

Notes: `-e ansible_become_password` is required (fresh box needs a sudo
password). Clone a non-default branch with `-e stow_version=<branch>`.
