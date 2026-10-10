# Migrating p15v to NixOS

Runbook for wiping the ThinkPad P15v (Ubuntu) and installing the NixOS configuration from this repo. The install has two stages, like a normal NixOS install:

1. **Stage 1** — from the plain NixOS minimal ISO: clone this repo and run `scripts/install-base`. It installs `p15v-base`: the disk layout (LUKS2 + btrfs), boot, your user and Wi-Fi, but no desktop.
2. **Stage 2** — on the installed system: clone the repo again and `nixos-rebuild switch` to the full `p15v` desktop.

`mise run vm:rehearsal` runs both stages unattended in QEMU, and `mise run vm:install` lets you do them by hand in a VM (see [Virtual run](#virtual-run)). Background on the configuration itself: `doc/nixos.md`.

## Gate — all must hold before Phase 1

- [ ] The commit you will install is pushed to GitHub (stage 1 and 2 clone it from there).
- [ ] `nix flake check -L` is green on that commit (`mise run nix:check`).
- [ ] `mise run vm:rehearsal` exits 0 on that commit.
- [ ] You did one [virtual run](#virtual-run) by hand.
- [ ] `secrets/p15v.yaml` and `secrets/p15v-ssh-host-key.enc` exist (`scripts/p15v-secrets-init`) and `sops decrypt secrets/p15v.yaml` works with the YubiKey (OpenPGP).
- [ ] `scripts/check-login-password` says `OK` for the password you will type at the login prompt. The system has no root password and `users.mutableUsers = false`: a wrong hash means no login and no sudo. (`install-base` checks it again before it wipes anything.)
- [ ] The offline backup age key is retrievable from Bitwarden (it decrypts both secrets files without the YubiKey).
- [ ] `mise run migration:preflight` shows no repo with unpushed or uncommitted work you still need (push or bundle them first).
- [ ] The restic backup below is done and a sample restore was verified.

## Phase 0 — backup and USB stick (on Ubuntu)

Replace `<disk>` with the external disk's mount name.

```bash
R=/media/$USER/<disk>/p15v-restic
nix shell nixpkgs#restic -c restic -r "$R" init
nix shell nixpkgs#restic -c restic -r "$R" backup ~ --exclude ~/.cache --exclude ~/.local/share/Trash --exclude '~/snap/*/common/.cache'
nix shell nixpkgs#restic -c restic -r "$R" restore latest --target /tmp/restore-test --include ~/.ssh
diff -r ~/.ssh /tmp/restore-test$HOME/.ssh && echo RESTORE-OK
```

USB stick: the official "Minimal ISO image" from <https://nixos.org/download> (unstable or the latest release), or the same thing built from this flake's nixpkgs:

```bash
nix build ~/.dot#nixosConfigurations.iso.config.system.build.isoImage -o /tmp/iso
lsblk                                   # find the USB stick, e.g. /dev/sdX
sudo dd if="$(ls /tmp/iso/iso/*.iso)" of=/dev/sdX bs=4M status=progress conv=fsync
```

## Phase 1 — stage 1 from the USB stick

Boot the stick (F12 at the Lenovo logo; Secure Boot off). Network: ethernet, or `nmcli device wifi connect <ssid> --ask`. Plug in the YubiKey.

```bash
sudo -i
git clone https://github.com/zezav-cz/.dot /tmp/dot
/tmp/dot/scripts/install-base
```

`install-base` asks before every step that matters and checks everything it can before touching the disk:

1. network;
2. decrypts the host key with the OpenPGP key on the YubiKey (card PIN); if the card does not work on the ISO it asks for the backup age key from Bitwarden instead, and checks the key against `secrets/p15v-ssh-host-key.pub`;
3. proves the host key decrypts `secrets/p15v.yaml` (what the installed system does at every boot) and that your login password matches the stored hash;
4. shows the target disk (`/dev/nvme0n1`, the 512 GB Toshiba) and wants `yes`;
5. asks the LUKS passphrase twice (ASCII letters and digits only: the initrd uses the plain us keymap);
6. disko (wipes the disk), host key into `/mnt/etc/ssh`, `nixos-install --flake /tmp/dot#p15v-base`.

Then `reboot` and remove the stick. At boot: LUKS passphrase, then the text login prompt.

## Phase 2 — stage 2 on the installed system

Log in as `jantrojak`. Wi-Fi `home` connects by itself (from the secrets); elsewhere use `nmcli device wifi connect <ssid> --ask`.

```bash
git clone https://github.com/zezav-cz/.dot ~/.dot
# builds as you (Nix refuses to read a repo you own as root), activates as root
nixos-rebuild switch --sudo --flake ~/.dot#p15v
reboot                                   # -> tuigreet -> sway
```

The first build downloads a lot and compiles the few local packages (NVIDIA module, claude-desktop, vn). After the reboot you get the full desktop; the dotfile links point at `~/.dot`.

## Phase 3 — restore

Mount the backup disk; NixOS mounts removable media under `/run/media`:

```bash
udisksctl mount -b /dev/sdX1              # or: sudo mount /dev/sdX1 /mnt
R=/run/media/$USER/<disk>/p15v-restic     # (or /mnt/p15v-restic)
restic() { nix shell nixpkgs#restic -c restic -r "$R" "$@"; }
restic restore latest --target / --include ~/.ssh --include ~/.gnupg --include ~/.aws --include ~/.kube --include ~/.config/gcloud --include ~/.claude --include ~/.claude-personal --include ~/.config/Claude-personal --include ~/.config/Claude-work --include ~/ops/vnotes
git -C ~/.dot remote set-url origin git@github.com:zezav-cz/.dot.git
nixos-rebuild switch --sudo --flake ~/.dot#p15v   # relinks what the restore replaced
~/.dot/scripts/bootstrap-user              # repo clones, vnotes, MCP servers
```

The backup contains the old stow symlinks inside `~/.gnupg`, `~/.claude` and `~/.claude-personal`. Restoring replaces the home-manager links there; the switch above moves the restored ones aside as `*.hm-backup` and relinks. If a later switch fails with "would be clobbered" because a `.hm-backup` already exists, delete the stale `.hm-backup` files and switch again.

Firefox: the old profile is under `~/snap/firefox/common/.mozilla/firefox/` in the backup; restore that directory to `~/.mozilla/firefox/`.

## Phase 4 — hardware checklist (what the VM cannot cover)

- [ ] Sway runs on the iGPU: `tr '\0' '\n' < /proc/$(pgrep -x sway)/environ | grep WLR_DRM_DEVICES` → `/dev/dri/igpu`.
- [ ] dGPU offload: `nvidia-offload glxinfo -B | grep -i nvidia` (glxinfo: `nix shell nixpkgs#mesa-demos`).
- [ ] dGPU idle power: `cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` while nothing uses it (Pascal has no fine-grained RTD3, so `active` is expected; check the battery drain).
- [ ] External monitor on DP-1 lights up. If it stays black, that port is wired to the NVIDIA GPU: add it to `WLR_DRM_DEVICES` in `hosts/p15v/nvidia.nix` (e.g. `/dev/dri/igpu:/dev/dri/card0`, check `ls -l /dev/dri/by-path`).
- [ ] kanshi switches between the `docked` and `laptop` profiles.
- [ ] Wi-Fi `home` profile connects (`nmcli connection show`), Bluetooth works (`bluetoothctl show`).
- [ ] Audio: `wpctl status` lists the speakers; volume and mute keys work.
- [ ] Brightness and media keys.
- [ ] Lid close suspends on battery, keeps running on AC.
- [ ] YubiKey: `ykman info`, `ssh -T git@github.com`, `gpg --card-status`.
- [ ] Firmware: `fwupdmgr get-devices`.
- [ ] Snapshots: after an hour, `snapper -c home list` shows a timeline snapshot.

## Rollback and recovery

- A configuration change breaks something: pick the previous generation in the systemd-boot menu, then `sudo nixos-rebuild switch --rollback`.
- Stage 2 fails: you still have the working `p15v-base` system; fix the repo (on another machine or with `nano` on the laptop) and run the switch again.
- Cannot log in (wrong password hash): boot the USB stick, `cryptsetup open /dev/nvme0n1p2 cryptroot`, `mount -o subvol=@root /dev/mapper/cryptroot /mnt`, `mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix`, `mount /dev/nvme0n1p1 /mnt/boot`. Fix `user-password` in `secrets/p15v.yaml` (`sops secrets/p15v.yaml`, on another machine or the stick with the YubiKey), push, clone it on the stick and re-run `nixos-install --no-root-passwd --flake <clone>#p15v-base` against the mounted system.
- The install itself is unusable: boot an Ubuntu ISO, reinstall, and restore `~` from restic. Ubuntu is gone after stage 1 wipes the disk; the backup is the only way back.

## Virtual run

The same two stages by hand in a VM, with the VM targets: `install-base --vm` installs `p15v-rehearsal-base` to `/dev/vda` with the throwaway VM secrets (login password `vm`) and the rehearsal host key, so no YubiKey is needed.

```bash
mise run vm:install          # QEMU window: NixOS ISO + empty 64 GB disk (UEFI)
```

In the VM:

```bash
sudo -i
git clone https://github.com/zezav-cz/.dot /tmp/dot
/tmp/dot/scripts/install-base --vm       # login password: vm; any LUKS passphrase
reboot                                   # boots the installed disk
# LUKS prompt: the VM variant shows it on the serial console, so in the QEMU
# window open View -> serial0 (Ctrl+Alt+2), type it there, then back with Ctrl+Alt+1
# log in as jantrojak / vm
git clone https://github.com/zezav-cz/.dot ~/.dot
nixos-rebuild switch --sudo --flake ~/.dot#p15v-rehearsal   # sudo password: vm
reboot                                   # -> tuigreet -> sway
```

The disk persists across `mise run vm:install` runs; `mise run vm:install:reset` starts over. The VM clones from GitHub, so it tests what is pushed.

## Afterwards (separate change)

Once p15v runs NixOS, remove what only Ubuntu needs: `ansible/` (except `playbook-user.yml` and the user roles), `installer/`, `install.py`, the standalone `homeConfigurations` and `home/generic-linux.nix`, `checks.dotfiles-parity`; the Ubuntu-only `/etc/udev/rules.d/99-kvm-nix.rules` disappears with the wipe.
