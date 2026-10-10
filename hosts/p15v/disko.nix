# GPT: ESP + LUKS2 -> btrfs subvolumes. The LUKS passphrase is read from
# /tmp/secret.key only while formatting (doc/nixos-migration.md).
{ config, lib, ... }:
let
  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  options.p15v.disk = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1";
    description = "Whole disk disko partitions (wiped!).";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.p15v.disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/secret.key";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                # snapper's config for /home expects /home/.snapshots
                "@home-snapshots" = {
                  mountpoint = "/home/.snapshots";
                  mountOptions = btrfsOpts;
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
