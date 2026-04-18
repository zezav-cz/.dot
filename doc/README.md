# Dotfiles

Personal dotfiles for bootstrapping a Fedora Sway Spin system. Manages
configuration for Sway WM, Neovim, Zsh, and a full suite of development and
desktop tools.

## Philosophy

- **GNU Stow** manages symlinks -- each subdirectory of `stow/` is a stow
  package whose contents mirror `~/`.
- **Python installer** (`install.py`) automates system bootstrap: repos,
  packages, shell setup, apps, fonts, stow linking, and private repos.
- Configs are portable across machines; package installation is
  distro-specific.

## Quick start

```bash
git clone <repo-url> ~/.dot
cd ~/.dot
python3 install.py
```

Common flags:

```bash
python3 install.py --list               # show available steps
python3 install.py --only stow          # run one step
python3 install.py --skip repos packages  # skip heavy steps
python3 install.py --dry-run            # preview without changes
python3 install.py -v                   # verbose output
```

## Further reading

- [architecture.md](architecture.md) -- installer internals and step pipeline
- [configs.md](configs.md) -- what each stow package configures
- [adding-a-package.md](adding-a-package.md) -- how to add a new stow package or installer step
- [distro-support.md](distro-support.md) -- multi-distro portability status
