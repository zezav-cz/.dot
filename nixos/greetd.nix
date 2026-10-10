# Replaces ansible/roles/greetd.
{ config, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd ${config.programs.sway.package}/bin/sway";
      user = "greeter";
    };
  };
}
