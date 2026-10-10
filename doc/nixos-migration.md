# Migrating p15v to NixOS

Runbook for wiping the ThinkPad P15v (Ubuntu) and installing the NixOS configuration from this repo. The install commands in Phase 1 are the same ones `mise run vm:rehearsal` runs in QEMU (`scripts/vm-rehearsal`), so they have been exercised end to end before they touch the laptop. Background on the configuration itself: `doc/nixos.md`.

## Gate — all must hold before Phase 1

- [ ] `nix flake check -L` is green on the commit you will install (`mise run nix:check`).
- [ ] `mise run vm:rehearsal` exits 0 on that commit.
- [ ] `secrets/p15v.yaml` and `secrets/p15v-ssh-host-key.enc` exist (`scripts/p15v-secrets-init`) and `sops decrypt secrets/p15v.yaml` works with the YubiKey.
- [ ] The offline backup age key is retrievable from Bitwarden.
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

nix build ~/.dot#nixosConfigurations.iso.config.system.build.isoImage -o /tmp/iso
lsblk                                   # find the USB stick, e.g. /dev/sdX
sudo dd if="$(ls /tmp/iso/iso/*.iso)" of=/dev/sdX bs=4M status=progress conv=fsync
```

## Phase 1 — install (from the USB stick)

Boot the stick (F12 at the Lenovo logo; Secure Boot off). Connect to the network: `nmcli device wifi connect <ssid> --ask`, or plug in ethernet. The install downloads packages from cache.nixos.org and builds the few local ones (NVIDIA module, claude-desktop, vn); the flake and all its inputs, the private `vn` repo included, are already on the stick.

```bash
sudo -i
nix flake metadata --offline /etc/dot >/dev/null && echo FLAKE-OK

# LUKS passphrase: ASCII letters/digits only -- the initrd has the plain us keymap.
read -rs PASS; printf %s "$PASS" > /tmp/secret.key; unset PASS

disko --mode destroy,format,mount --yes-wipe-all-disks --flake /etc/dot#p15v

# host key: sops decrypts it with the YubiKey identity (PIN + touch)
age-plugin-yubikey --identity > /tmp/id.txt
export SOPS_AGE_KEY_FILE=/tmp/id.txt
install -d -m 755 /mnt/etc/ssh
sops decrypt --input-type binary --output-type binary /etc/dot/secrets/p15v-ssh-host-key.enc > /mnt/etc/ssh/ssh_host_ed25519_key
cp /etc/dot/secrets/p15v-ssh-host-key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub
chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key

nixos-install --no-root-passwd --flake /etc/dot#p15v
reboot
```

At boot: LUKS passphrase, then tuigreet → `jantrojak` with the password chosen in `scripts/p15v-secrets-init`.

## Phase 2 — hardware checklist (what the VM cannot cover)

- [ ] Sway runs on the iGPU: `tr '\0' '\n' < /proc/$(pgrep -x sway)/environ | grep WLR_DRM_DEVICES` → `/dev/dri/igpu`.
- [ ] dGPU offload: `nvidia-offload glxinfo -B | grep -i nvidia` (glxinfo: `nix shell nixpkgs#mesa-demos`).
- [ ] External monitor on DP-1 lights up. If it stays black, that port is wired to the NVIDIA GPU: add it to `WLR_DRM_DEVICES` in `hosts/p15v/nvidia.nix` (e.g. `/dev/dri/igpu:/dev/dri/card0`, check `ls -l /dev/dri/by-path`).
- [ ] kanshi switches between the `docked` and `laptop` profiles.
- [ ] Wi-Fi `home` profile connects (`nmcli connection show`), Bluetooth works (`bluetoothctl show`).
- [ ] Audio: `wpctl status` lists the speakers; volume and mute keys work.
- [ ] Brightness and media keys.
- [ ] Lid close suspends on battery, keeps running on AC.
- [ ] YubiKey: `ykman info`, `ssh -T git@github.com`, `gpg --card-status`.
- [ ] Firmware: `fwupdmgr get-devices`.
- [ ] Snapshots: after an hour, `snapper -c home list` shows a timeline snapshot.

## Phase 3 — restore

```bash
git clone git@github.com:zezav-cz/.dot.git ~/.dot
sudo nixos-rebuild switch --flake ~/.dot#p15v      # links now point at the real checkout
nix shell nixpkgs#restic -c restic -r "$R" restore latest --target / --include ~/.ssh --include ~/.gnupg --include ~/.aws --include ~/.kube --include ~/.config/gcloud --include ~/.claude --include ~/.claude-personal --include ~/.config/Claude-personal --include ~/.config/Claude-work --include ~/ops/vnotes
~/.dot/scripts/bootstrap-user                     # repo clones, vnotes, MCP servers
```

Firefox: the old profile is under `~/snap/firefox/common/.mozilla/firefox/` in the backup; restore that directory to `~/.mozilla/firefox/`.

## Rollback

- A configuration change breaks something: pick the previous generation in the systemd-boot menu, then `sudo nixos-rebuild switch --rollback`.
- The install itself is unusable: boot an Ubuntu ISO, reinstall, and restore `~` from restic. Ubuntu is gone after `disko --mode destroy`; the backup is the only way back.

## Afterwards (separate change)

Once p15v runs NixOS, remove what only Ubuntu needs: `ansible/` (except `playbook-user.yml` and the user roles), `installer/`, `install.py`, the standalone `homeConfigurations` and `home/generic-linux.nix`, and `checks.dotfiles-parity`.
