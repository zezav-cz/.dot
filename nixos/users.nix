{ config, pkgs, ... }:
{
  users.mutableUsers = false;
  sops.secrets.user-password.neededForUsers = true;

  programs.zsh.enable = true;

  users.users.jantrojak = {
    isNormalUser = true;
    uid = 1001; # same as on Ubuntu: restored files and 9p shares keep their owner
    description = "Jan Trojak";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    openssh.authorizedKeys.keyFiles = [ ../keys/jantrojak.pub ];
  };
}
