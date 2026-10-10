{ config, pkgs, ... }:
{
  users.mutableUsers = false;
  sops.secrets.user-password.neededForUsers = true;

  programs.zsh.enable = true;

  # User private group with the Ubuntu ids: files restored from the backup or
  # shared over 9p keep uid/gid 1001 and (umask 002) group write, which zsh's
  # compaudit would otherwise flag as writable by a foreign group.
  users.groups.jantrojak.gid = 1001;

  users.users.jantrojak = {
    isNormalUser = true;
    uid = 1001; # same as on Ubuntu: restored files and 9p shares keep their owner
    group = "jantrojak";
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
