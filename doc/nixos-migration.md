# Migrating p15v to NixOS

Runbook for wiping the ThinkPad P15v (Ubuntu) and installing the NixOS configuration from this repo. The install commands in Phase 1 are the same ones `mise run vm:rehearsal` runs in QEMU (`scripts/vm-rehearsal`), so they have been exercised end to end before they touch the laptop. Background on the configuration itself: `doc/nixos.md`.

## Gate — all must hold before Phase 1

- [ ] The commit you will install is pushed and the ISO is built from it (Phase 0), not from a dirty working tree.
- [ ] `nix flake check -L` is green on that commit (`mise run nix:check`).
- [ ] `mise run vm:rehearsal` exits 0 on that commit.
- [ ] `secrets/p15v.yaml` and `secrets/p15v-ssh-host-key.enc` exist (`scripts/p15v-secrets-init`) and `sops decrypt secrets/p15v.yaml` works with the YubiKey (OpenPGP).
- [ ] `scripts/check-login-password` says `OK` for the password you will type at the login prompt. The system has no root password and `users.mutableUsers = false`: a wrong hash means no login and no sudo.
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

# ISO from the pushed commit, not the working tree
rev=$(git -C ~/.dot rev-parse HEAD); git -C ~/.dot status --short | head
nix build "git+file://$HOME/.dot?rev=$rev#nixosConfigurations.iso.config.system.build.isoImage" -o /tmp/iso
lsblk                                   # find the USB stick, e.g. /dev/sdX
sudo dd if="$(ls /tmp/iso/iso/*.iso)" of=/dev/sdX bs=4M status=progress conv=fsync
```

## Phase 1 — install (from the USB stick)

Boot the stick (F12 at the Lenovo logo; Secure Boot off). Connect to the network: ethernet, or `nmcli device wifi connect <ssid> --ask`. The install downloads packages from cache.nixos.org and builds the few local ones (NVIDIA module, claude-desktop, vn); the flake and all its inputs, the private `vn` repo included, are already on the stick.

```bash
sudo -i
nix flake metadata --offline /etc/dot >/dev/null && echo FLAKE-OK

# 1. host key first, while the disk is still intact: it is encrypted to the
#    OpenPGP key on the YubiKey (card PIN when asked)
gpg --import /etc/dot/keys/jantrojak-pgp.asc
gpg --card-status >/dev/null              # creates the card stubs for the subkeys
export GPG_TTY=$(tty)
sops decrypt --input-type binary --output-type binary /etc/dot/secrets/p15v-ssh-host-key.enc > /tmp/ssh_host_ed25519_key
#    Fallback if the card does not work here: paste the backup age key from
#    Bitwarden into /tmp/backup.agekey and run the same line with
#    SOPS_AGE_KEY_FILE=/tmp/backup.agekey in front.
test -s /tmp/ssh_host_ed25519_key && echo HOSTKEY-OK

# 2. the target disk: must be the internal 512 GB Toshiba NVMe (KXG6AZNV512G)
lsblk -dno NAME,SIZE,MODEL /dev/nvme0n1

# 3. LUKS passphrase, typed twice. ASCII letters/digits only: the initrd has
#    the plain us keymap.
read -rsp 'LUKS passphrase: ' P1; echo; read -rsp 'Again: ' P2; echo
[ "$P1" = "$P2" ] && printf %s "$P1" > /tmp/secret.key && echo PASS-OK; unset P1 P2

disko --mode destroy,format,mount --yes-wipe-all-disks --flake /etc/dot#p15v

install -d -m 755 /mnt/etc/ssh
install -m 600 /tmp/ssh_host_ed25519_key /mnt/etc/ssh/ssh_host_ed25519_key
cp /etc/dot/secrets/p15v-ssh-host-key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub

nixos-install --no-root-passwd --flake /etc/dot#p15v
reboot
```

At boot: LUKS passphrase, then tuigreet → `jantrojak` with the password checked in the gate. The desktop is still bare at this point: every dotfile link points at `~/.dot`, which Phase 2 creates.

## Phase 2 — restore and switch to the real checkout

Log in on tty2 (Ctrl+Alt+F2) or in the plain sway session. Mount the backup disk; NixOS mounts removable media under `/run/media`:

```bash
udisksctl mount -b /dev/sdX1              # or: sudo mount /dev/sdX1 /mnt
R=/run/media/$USER/<disk>/p15v-restic     # (or /mnt/p15v-restic)
restic() { nix shell nixpkgs#restic -c restic -r "$R" "$@"; }

# SSH and GPG first: the clone below needs the keys in ~/.ssh/keys
restic restore latest --target / --include ~/.ssh --include ~/.gnupg
rm -rf ~/.gnupg/*.conf.hm-backup 2>/dev/null   # see the note below

git clone git@github.com:zezav-cz/.dot.git ~/.dot
# evaluate as the user (whose agent can reach the private vn repo), activate as root
nixos-rebuild switch --sudo --flake ~/.dot#p15v

restic restore latest --target / --include ~/.aws --include ~/.kube --include ~/.config/gcloud --include ~/.claude --include ~/.claude-personal --include ~/.config/Claude-personal --include ~/.config/Claude-work --include ~/ops/vnotes
~/.dot/scripts/bootstrap-user              # repo clones, vnotes, MCP servers
```

Log out and back in through tuigreet: now the full sway session (kanshi, waybar, keybindings) comes up.

Note: the backup contains the old stow symlinks inside `~/.gnupg`, `~/.claude` and `~/.claude-personal`. Restoring over the home-manager links replaces them; the next activation moves the restored ones aside as `*.hm-backup` and relinks. If an activation ever fails with "would be clobbered" because a `.hm-backup` already exists, delete the stale `.hm-backup` files and run the switch again.

Firefox: the old profile is under `~/snap/firefox/common/.mozilla/firefox/` in the backup; restore that directory to `~/.mozilla/firefox/`.

## Phase 3 — hardware checklist (what the VM cannot cover)

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
- Cannot log in (wrong password hash): boot the USB stick, then `cryptsetup open /dev/nvme0n1p2 cryptroot`, `mount -o subvol=@root /dev/mapper/cryptroot /mnt`, `mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix`, `mount /dev/nvme0n1p1 /mnt/boot`. On another machine (or the ISO with the YubiKey) fix `user-password` in `secrets/p15v.yaml` (`sops secrets/p15v.yaml`), commit, and re-run `nixos-install --no-root-passwd --flake <repo>#p15v` against the mounted system.
- The install itself is unusable: boot an Ubuntu ISO, reinstall, and restore `~` from restic. Ubuntu is gone after `disko --mode destroy`; the backup is the only way back.

## Afterwards (separate change)

Once p15v runs NixOS, remove what only Ubuntu needs: `ansible/` (except `playbook-user.yml` and the user roles), `installer/`, `install.py`, the standalone `homeConfigurations` and `home/generic-linux.nix`, `checks.dotfiles-parity`, and the Ubuntu-only `/etc/udev/rules.d/99-kvm-nix.rules` disappears with the wipe.
