# Wi-Fi profiles with passwords from sops (secrets/p15v.yaml, key wifi-env:
# KEY=value lines). Add a network: a profile here + its variables there.
{ config, ... }:
{
  sops.secrets.wifi-env = { };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets.wifi-env.path ];
    profiles.home = {
      connection = {
        id = "home";
        type = "wifi";
      };
      wifi = {
        ssid = "$HOME_SSID";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$HOME_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };
}
