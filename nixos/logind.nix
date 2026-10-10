# Replaces ansible/roles/logind: keep running with the lid closed on AC
# (docked), suspend on battery as usual.
{
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
}
