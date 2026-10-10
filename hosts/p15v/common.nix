# Everything about p15v except its real hardware; shared with the install
# rehearsal (hosts/p15v-rehearsal.nix).
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./snapper.nix
  ];

  networking.hostName = "p15v";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  sops.defaultSopsFile = ../../secrets/p15v.yaml;
}
