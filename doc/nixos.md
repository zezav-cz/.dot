# NixOS

The repo also defines the NixOS system for the p15v laptop (ThinkPad P15v Gen 1). Ubuntu keeps working from the same files until the migration (`doc/nixos-migration.md`): the standalone `homeConfigurations.jantrojak` and the stow/ansible setup are untouched by everything below.

## Layout

| Path | What it is |
|---|---|
| `flake.nix` | inputs, `mkHost`, `nixosConfigurations`, `homeConfigurations`, `checks`, `formatter` |
| `nixos/` | system modules shared by every host, one per former ansible role (`base`, `users`, `secrets`, `home`, `shell`, `desktop-sway`, `greetd`, `logind`, `fonts`, `security`, `theme`) |
| `hosts/vm/` | QEMU guest: `default.nix` (used by the NixOS test too) and `interactive.nix` (GL display, live repo) |
| `hosts/p15v/` | the laptop: `base.nix` (disk, boot, firmware, Wi-Fi; stage 1 of the install) and `default.nix` (+ NVIDIA) |
| `hosts/p15v-rehearsal.nix`, `hosts/iso/` | the same two install stages in QEMU, and the plain NixOS minimal ISO |
| `nixos/minimal.nix` | the subset of `nixos/` stage 1 (`p15v-base`) installs: nix, network, sshd, sops, the user |
| `home/` | the user environment: `default.nix`, `packages.nix`, `dotfiles.nix`, `dotfiles-packages.nix`; `generic-linux.nix` is Ubuntu-only |
| `checks/`, `tests/` | `nix flake check` definitions and the headless desktop test |
| `keys/` | public keys: `jantrojak.pub` (SSH, the user's `authorized_keys`), `jantrojak-pgp.asc` (the YubiKey's OpenPGP key, sops recipient) |
| `scripts/install-base`, `scripts/vm-rehearsal`, `scripts/vm-install` | stage 1 of the install, its automated rehearsal, and a VM for a run by hand (`doc/nixos-migration.md`) |
| `.sops.yaml`, `secrets/` | sops recipients and encrypted secrets |

Every host gets the same `pkgs` instance (`allowUnfree`), so modules under `nixos/` and `hosts/` never set `nixpkgs.config`.

## How dotfiles are linked

`home/dotfiles.nix` replaces GNU stow on NixOS. It links `stow/<pkg>/…` into `~` with `mkOutOfStoreSymlink`, so the links point at the working copy (`dotfiles.root`, default `~/.dot`) rather than the store: editing a file takes effect without a rebuild, exactly as with stow.

- Packages in `folded` (`home/dotfiles-packages.nix`) are linked like stow folds them: `~/.config/<dir>` and other top-level entries become one link each, so new files under them appear without a rebuild.
- Packages in `noFolding` are linked per file, so runtime state written next to them (Claude sessions, the gnupg keyring, lazygit `state.yml`) lands in a real directory in `~`, not in the repo. `~/.gnupg` is chmod 700 on activation.
- `stow/systemd/.config/systemd` and `.config/environment.d` are linked per file because home-manager writes its own files there (`systemd/user/tray.target`, `environment.d/10-home-manager.conf`). A new user unit therefore needs a rebuild.
- Only packages tracked in git are visible to the flake; an untracked package is skipped.
- The lists mirror `STOW_PACKAGES`/`STOW_NO_FOLDING` in `installer/config.py`; `checks.dotfiles-parity` fails if they drift.

home-manager runs with `useUserPackages = false`, so packages land in `~/.nix-profile` as on Ubuntu (`.zshrc`'s fpath and `plantuml-server.service` rely on that). oh-my-zsh and its plugins come from nixpkgs through `$ZSH`/`$ZSH_CUSTOM` (`nixos/shell.nix`); the stowed `.zshrc` falls back to `~/.oh-my-zsh` when they are unset.

The user has a private group `jantrojak` with gid 1001, like on Ubuntu: restored or 9p-shared files keep gid 1001 and group write (umask 002), and zsh's compaudit would reject them under a foreign group.

## VM

| Task | What it does |
|---|---|
| `mise run vm` | builds `nixosConfigurations.vm` and opens it in QEMU (KVM, virtio-gpu GL); log in as `jantrojak` / `vm` |
| `mise run vm:reset` | deletes `.vm/vm.qcow2`, the next boot starts from a fresh disk |
| `mise run vm:test` | runs the headless desktop test, screenshot at `.vm/test/desktop.png` |
| `mise run vm:install` / `vm:install:reset` | QEMU window with the plain NixOS ISO and an empty disk, for doing the two-stage install by hand |
| `mise run vm:rehearsal` | both install stages unattended in QEMU, with checks after each |

The interactive VM mounts the host's `~/.dot` at `/mnt/dot` (9p) and links `~/.dot` to it; edit a file on the host and run `swaymsg reload` in the guest. If sway shows a black screen (host without virgl), add `WLR_RENDERER = "pixman"` to `environment.sessionVariables` in `hosts/vm/interactive.nix`.

NixOS tests need KVM inside the nix build sandbox. On the Ubuntu host that is the udev rule `/etc/udev/rules.d/99-kvm-nix.rules` (`KERNEL=="kvm", GROUP="kvm", MODE="0666"`); without it the tests fall back to slow emulation.

## Checks

`nix flake check` (`mise run nix:check`) runs:

- `nix-lint` — `nixfmt --check`, `statix` (config in `statix.toml`), `deadnix` over every `.nix` file outside `stow/`
- `portable-paths` — `scripts/check-portable-paths`: stowed configs must not call `/usr/bin/x`, `/bin/bash` and the like (use `/usr/bin/env x`)
- `dotfiles-parity` — installer and nix stow lists are the same
- `desktop` — the NixOS test: sops password, home-manager links, runtime files outside the repo, clean `zsh -ic`, greetd login into sway, session units (`sway-session.target`, waybar, swaync, kanshi, ssh-agent, portal), every binary the sway config calls, `swaymsg reload` keeping the session

`mise run nix:fmt` formats all Nix files; lefthook runs `nixfmt --check` on staged `.nix` files.

## Secrets

sops-nix with age. `.sops.yaml` lists the recipients per file: `secrets/p15v.yaml` is encrypted to the OpenPGP key on the YubiKey (PIV stays off, see `doc/yubikey.md`), an offline backup age key kept in Bitwarden, and the laptop's SSH host key (`scripts/p15v-secrets-init` created them). `secrets/vm.yaml` holds only the VM test password (`vm`) and is encrypted for a throwaway key committed on purpose (`secrets/vm-test.agekey`); the VM copies it to `/run` at activation because sops-nix refuses a key file in the store. Edit it with:

```sh
SOPS_AGE_KEY_FILE=secrets/vm-test.agekey nix shell --inputs-from . nixpkgs#sops -c sops secrets/vm.yaml
```

Every host's sops file must contain `user-password` (a yescrypt hash from `mkpasswd -m yescrypt`); `users.mutableUsers = false`, so it is the only password the user has.
