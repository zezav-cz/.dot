# Only for `mise run vm` (not the NixOS test): GL display and the live repo.
{
  virtualisation = {
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
    # Relative to the repo root, where `mise run vm` starts QEMU.
    diskImage = "./.vm/vm.qcow2";
    # The host working copy: edit on the host, `swaymsg reload` in the guest.
    sharedDirectories.dot = {
      source = "/home/jantrojak/.dot";
      target = "/mnt/dot";
    };
  };

  home-manager.users.jantrojak =
    { config, ... }:
    {
      dotfiles.root = "/mnt/dot";
      home.file.".dot".source = config.lib.file.mkOutOfStoreSymlink "/mnt/dot";
    };

  # If sway shows a black screen (host without virgl), log in on tty2 and
  # add WLR_RENDERER = "pixman" here.
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
}
