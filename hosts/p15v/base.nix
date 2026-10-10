# The laptop without its desktop: disk, boot, firmware, CPU, Wi-Fi. Stage 1
# of the install is this alone (p15v-base); default.nix adds the GPU setup
# that only matters for sway.
{ inputs, ... }:
{
  imports = [
    ./common.nix
    ./hardware.nix
    ./wifi.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
}
