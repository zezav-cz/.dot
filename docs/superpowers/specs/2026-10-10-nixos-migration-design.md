# NixOS migration of the p15v laptop — design

**Date:** 2026-10-10
**Status:** Approved (amended while planning, see `docs/superpowers/plans/2026-10-10-nixos-migration.md` § Deviations)

## Goal

Move the ThinkPad P15v Gen 1 (hostname `p15v`) from Ubuntu 26.04 + ansible/installer/stow to NixOS with Sway, managed from this repo's flake. The whole system must be built, booted and tested in a VM — including a full install rehearsal — before the laptop is wiped, so the bare-metal migration is a known, scripted procedure.

## Decisions (agreed during brainstorming)

- **Hybrid configs:** system, packages and look are in Nix; existing files under `stow/` are linked by home-manager with `mkOutOfStoreSymlink` into the `~/.dot` working copy, so editing them takes effect without a rebuild and they stay shared with Ubuntu until migration. Converting individual configs to native home-manager modules is a later, optional step.
- **Disk:** declarative with disko — GPT, ESP + LUKS2 → btrfs subvolumes. No impermanence.
- **Secrets:** sops-nix with age.
- **Testing:** fast iteration loop via `build-vm` + a headless NixOS test in `nix flake check`, plus one scripted install rehearsal that runs the runbook's own `disko` + `nixos-install` commands from the installer ISO into an empty QEMU disk (the laptop has no second machine for nixos-anywhere, so the rehearsal uses the same procedure as the real install).
- **Channel:** nixos-unstable, the same nixpkgs `home.nix` already uses.
- **Task runner:** mise tasks (this repo's convention), not just.

## Out of scope (v1)

- NVIDIA tuning beyond a sane PRIME-offload default — verified only on hardware.
- Impermanence / erase-your-darlings.
- Rewriting dotfiles into native home-manager modules.
- Removing `ansible/`, `installer/`, the standalone `homeConfigurations` and `targets.genericLinux` — a separate follow-up after the migration.
- Hibernation.

## 1. Flake and module layout

```
.sops.yaml                # sops recipients
flake.nix                 # + nixosConfigurations.{p15v,p15v-rehearsal,vm,iso}, checks
hosts/
  p15v/default.nix        # nixos-hardware (Intel CPU, NVIDIA PRIME offload), hostname, imports disko.nix
  p15v/disko.nix          # disk layout, device taken from an option
  p15v/common.nix         # disko, snapper, bootloader, sops file (shared with the rehearsal)
  p15v/hardware.nix       # nixos-generate-config --no-filesystems, generated on the Ubuntu host
  p15v-rehearsal.nix      # p15v + overrides: /dev/vda, no NVIDIA/nixos-hardware, virtio
  vm/default.nix          # build-vm variant: virtio-gpu GL, 8 GiB RAM, 4 vCPU, ~/.dot shared in
  iso/default.nix         # minimal installer ISO: sshd with the user's key, flake + all input sources, disko, sops
nixos/                    # system modules, one per former ansible role
  base.nix                # nix settings (flakes, gc, substituters), locale, tz, NetworkManager, systemd-boot
  users.nix               # jantrojak, zsh, groups, hashedPasswordFile from sops
  desktop-sway.nix        # programs.sway, xdg portals (wlr + gtk), pipewire, polkit, swaylock PAM
  greetd.nix              # greetd + tuigreet → sway
  logind.nix              # lid close on external power = ignore
  fonts.nix               # fonts.packages
  security.nix            # pcscd, YubiKey udev, gnupg agent, sops-nix wiring
  shell.nix               # zsh, ZSH/ZSH_CUSTOM -> oh-my-zsh + plugins from nixpkgs, direnv
  theme.nix               # stylix gruvbox for the console and fontconfig only
home/                     # home-manager modules (split of today's home.nix)
  default.nix             # imports; option dotfiles.root (default ~/.dot)
  packages.nix            # today's home.packages, unchanged
  dotfiles.nix            # mkOutOfStoreSymlink links into ${dotfiles.root}/stow
secrets/
  p15v.yaml, vm.yaml      # encrypted
  vm-test.agekey          # throwaway key, VM-only, committed on purpose
scripts/
  vm-rehearsal            # install rehearsal driver
  migration-preflight     # read-only pre-wipe report
  bootstrap-user          # idempotent post-install user setup
```

- `home/default.nix` is the single source of truth for the user environment. NixOS imports it via `home-manager.users.jantrojak`; the standalone `homeConfigurations.jantrojak` (Ubuntu) imports it plus `targets.genericLinux`. Ubuntu keeps working until migration.
- `p15v`, `p15v-rehearsal` and `vm` share every module in `nixos/`; they differ only under `hosts/`.
- New flake inputs, all with `inputs.nixpkgs.follows = "nixpkgs"` where applicable: `disko`, `sops-nix`, `stylix`, `nixos-hardware`.

## 2. Mapping today's setup to NixOS

| Today | NixOS |
|---|---|
| `ansible/roles/packages-base`, `packages-full` | `environment.systemPackages` for system tools; user tools stay in `home/packages.nix` |
| `sway-minimal`, `sway-portability` | `programs.sway` (+ `wrapperFeatures.gtk`), `xdg.portal`; the ansible asserts become NixOS test assertions |
| `greetd` (+ getty conflict drop-in) | `services.greetd` with tuigreet |
| `logind` | `services.logind` lid-switch-external-power = ignore |
| `fonts` | `fonts.packages` from nixpkgs |
| `shell` (oh-my-zsh clone, chsh) | `programs.zsh.enable`, user shell = zsh; oh-my-zsh and plugins from nixpkgs exposed via `ZSH`/`ZSH_CUSTOM` set by NixOS (`environment.variables`, since the stowed `.zshrc` does not source home-manager's session vars); `.zshrc` honours a preset `$ZSH` (still works on Ubuntu) |
| `apps` | already in `home.nix` |
| `vnotes`, `dev-repos`, `git-clone`, `mcp` | user data, not system state → `scripts/bootstrap-user` |
| ssh-agent / YubiKey | `services.pcscd`, `hardware.gpgSmartcards`, YubiKey udev rules |
| `mise` | not activated on NixOS (home.nix already mirrors its tools); config stays linked |

### Dotfiles

- `link = path: config.lib.file.mkOutOfStoreSymlink "${cfg.root}/stow/${path}"`.
- Packages stow folds (sway, nvim, tmux, zsh, rofi, systemd, …) are linked as whole directories.
- Packages in `STOW_NO_FOLDING` (foot, k9s, lazygit, claude, claude-personal, gnupg, lnav, vscode, pgcli, pandoc, my-scripts) are linked per file, so runtime-written files (`foot/theme-mode.ini`, `k9s/config.yaml`, lazygit `state.yml`, Claude sessions, the gnupg keyring) stay outside the repo.
- The package list lives in `home/dotfiles.nix`; `installer/config.py` keeps its own list for Ubuntu. A flake check compares the two sets until the installer is removed.
- `stow/systemd/.config/systemd/user` is linked as a directory; its `*.wants/` symlinks are relative and keep working. The dangling `snap.firmware-updater.firmware-notifier.timer` link is removed (Ubuntu-only).

## 3. VM and automated tests

### Interactive VM — `mise run vm`

- Builds `nixosConfigurations.vm.config.system.build.vm` and runs it under QEMU/KVM with `virtio-vga-gl` and `-display gtk,gl=on`; falls back to `WLR_RENDERER=pixman` if host virgl fails.
- The host's `~/.dot` is shared into the guest at `/mnt/dot` (`virtualisation.sharedDirectories`) with `~/.dot` linked to it and `dotfiles.root = /mnt/dot`, so out-of-store links resolve and host edits show up after `swaymsg reload`.
- Disk image lives in `./.vm/` (gitignored); `mise run vm:reset` deletes it.
- Login goes through real greetd/tuigreet with the password from `secrets/vm.yaml`, exercising PAM and sops.

### Headless test — `mise run vm:test` (part of `nix flake check`)

`checks.x86_64-linux.desktop` built with `pkgs.testers.runNixOSTest` from the same modules as `vm`. In the sandbox `dotfiles.root` points at `${self}` so links resolve to the repo copy in the store.

Assertions:

1. `greetd.service` up; log in via tuigreet with send_chars.
2. Sway IPC socket appears; `swaymsg -t get_tree` succeeds; `sway -C` validates the config.
3. User units active: `sway-session.target`, `kanshi`, `ssh-agent`, `waybar`; `battery-notify.timer` loaded.
4. `/etc/pam.d/swaylock` exists; `xdg-desktop-portal-wlr` running.
5. `zsh -ic 'echo ok'` as jantrojak succeeds (`.zshrc` + oh-my-zsh paths).
6. Screenshot saved as a test artefact.

Other checks:

- `checks.p15v-toplevel` builds `nixosConfigurations.p15v.config.system.build.toplevel`, so nothing reaches hardware that does not build (NVIDIA driver, disko, nixos-hardware).
- `checks.dotfiles-parity` — installer vs. `home/dotfiles.nix` package lists.
- Nix lint: `nixfmt`, `statix`, `deadnix` in the flake checks and as lefthook pre-commit hooks on staged `.nix` files.

Known limits: the private `vn` input is fetched over SSH at evaluation time (fine locally, no CI exists). The first full test build is slow; later runs hit the store.

## 4. Disk, secrets, install rehearsal

### Disk — `hosts/p15v/disko.nix`

- GPT; ESP 1 GiB vfat at `/boot` (systemd-boot).
- LUKS2 `cryptroot` over the rest, `allowDiscards`.
- btrfs, `compress=zstd,noatime`: `@root` → `/`, `@home` → `/home`, `@nix` → `/nix`, `@home-snapshots` → `/home/.snapshots` (where snapper's `home` config expects it), `@swap` → 16 GiB swapfile.
- Device is an option: `/dev/nvme0n1` on p15v, `/dev/vda` in the rehearsal; the layout is otherwise identical.
- snapper takes hourly `@home` snapshots with rotation; system rollback is NixOS generations.

### Secrets — sops-nix + age

Recipients (`.sops.yaml`):

- **Personal:** `age-plugin-yubikey` identity plus an offline backup age key.
- **p15v host:** age key derived from `/etc/ssh/ssh_host_ed25519_key`. The host key is generated before install, stored encrypted, and placed by the installer (`--extra-files`) so secrets decrypt on first boot.
- **VM:** throwaway `secrets/vm-test.agekey`, the only recipient of `secrets/vm.yaml`; contains no real data.

v1 secrets: user password hash (`hashedPasswordFile`, `neededForUsers`), Wi-Fi profiles (`networking.networkmanager.ensureProfiles` + env file), tokens consumed by `bootstrap-user`. SSH/GPG keys stay on the YubiKey.

### Install rehearsal — `mise run vm:rehearsal`

- `nixosConfigurations.iso` builds a minimal ISO (sshd with the user's key, the flake at `/etc/dot` and the source of every `flake.lock` node, so the private `vn` input is never fetched). The same ISO is the USB stick for the real install; `iso-rehearsal` adds only a throwaway SSH key and a serial console.
- `scripts/vm-rehearsal`:
  1. Creates an empty 64 GiB qcow2, boots the ISO under QEMU with port 2222 → 22.
  2. Over SSH runs exactly the runbook's Phase 1: passphrase to `/tmp/secret.key`, `disko --mode destroy,format,mount --flake /etc/dot#p15v-rehearsal`, host key into `/mnt/etc/ssh`, `nixos-install --flake /etc/dot#p15v-rehearsal`.
  3. Reboots from disk, enters the LUKS passphrase over the serial console.
  4. Verifies: greetd up, sops secrets decrypted, `/home` mounted from `@home`, snapper timer active.
- Success criterion for migration readiness: the rehearsal passes end to end without manual steps other than starting it.

## 5. Migration runbook

Written out as a checklist in `doc/nixos-migration.md`.

**Phase 0 — on Ubuntu**

- `scripts/migration-preflight` (read-only): repos under `~/dev` with unpushed commits or dirty worktrees; sizes of data outside the repo — `~/.ssh`, `~/.gnupg` card stubs, `~/.aws`, `~/.kube`, `~/.config/Claude-*`, `~/.claude*`, notes vaults, the Firefox snap profile in `~/snap/firefox` (moves to `~/.mozilla`).
- restic backup to an external disk; a sample restore is tested before wiping.
- Gate: `nix flake check` green, rehearsal passed, `p15v-toplevel` builds.

**Phase 1 — install**

1. Boot the installer ISO from USB, connect network.
2. From the ISO itself, the same commands the rehearsal runs: passphrase to `/tmp/secret.key`, `disko --mode destroy,format,mount --flake /etc/dot#p15v`, decrypt the host key (YubiKey) into `/mnt/etc/ssh`, `nixos-install --flake /etc/dot#p15v`.
3. Reboot → LUKS passphrase → greetd.

**Phase 2 — hardware verification (what the VM cannot cover)**

NVIDIA (Pascal → `legacy_580`, closed module; sway needs `--unsupported-gpu` while the module is loaded): Sway on the Intel iGPU via a udev `/dev/dri/igpu` symlink in `WLR_DRM_DEVICES`, `nvidia-offload` works, external monitor on DP-1 (if that port is wired to the NVIDIA GPU, add the dGPU to `WLR_DRM_DEVICES` — known risk). Wi-Fi, Bluetooth, PipeWire audio, brightness/media keys, suspend and lid on AC and battery, kanshi `docked`/`laptop`, YubiKey (ssh, gpg, pcscd), fwupd.

**Phase 3 — restore**

restic restore, `scripts/bootstrap-user` (repo clones, vnotes, MCP servers), sign in to apps.

**Rollback:** Ubuntu is gone after the wipe; the fallback is the verified backup plus an Ubuntu ISO. Config regressions roll back via the previous generation in systemd-boot.

## Risks

- **NVIDIA + Sway on hybrid graphics** — untestable in a VM; mitigated by running Sway on the iGPU and verifying in Phase 2.
- **Out-of-store links in the sandboxed test** — mitigated by the `dotfiles.root` option.
- **Single machine, destructive install** — mitigated by the rehearsal, the preflight report and a tested restore.
- **Two sources of package/dotfile lists until Ubuntu is retired** — mitigated by the parity check.
