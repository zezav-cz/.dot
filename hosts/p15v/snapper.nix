# Hourly /home snapshots; system rollback is NixOS generations instead.
{
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    ALLOW_USERS = [ "jantrojak" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "24";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
  };
}
