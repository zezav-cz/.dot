# ThinkPad P15v Gen 1. nixos-hardware has no profile for it; compose the
# common ones.
{ inputs, ... }:
{
  imports = [
    ./common.nix
    ./hardware.nix
    ./nvidia.nix
    ./wifi.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
}
