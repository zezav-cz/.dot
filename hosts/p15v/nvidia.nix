# Quadro P620 (Pascal) + Intel UHD. Sway renders on the iGPU; the dGPU is for
# `nvidia-offload <app>`. Pascal is dropped by the 590+ drivers and by the
# open kernel module, hence legacy_580 + open = false.
{ config, inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-nvidia ];

  services.xserver.videoDrivers = [ "nvidia" ]; # loads the driver, no X needed
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    modesetting.enable = true;
    powerManagement.finegrained = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0"; # lspci 00:02.0
      nvidiaBusId = "PCI:1:0:0"; # lspci 01:00.0
    };
  };

  # wlroots splits WLR_DRM_DEVICES on ':', so PCI by-path names can't be used.
  services.udev.extraRules = ''
    KERNEL=="card*", SUBSYSTEM=="drm", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
  '';
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/igpu";
  # sway refuses to start while the proprietary module is loaded at all.
  programs.sway.extraOptions = [ "--unsupported-gpu" ];
}
