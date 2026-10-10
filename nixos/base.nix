{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  # The LUKS passphrase is typed in the initrd, before sway's us,cz switching
  # exists: keep the console on plain us so the passphrase means the same keys.
  console.keyMap = "us";

  networking.networkmanager.enable = true;

  # sops-nix derives the host age key from the ed25519 host key, so sshd must
  # exist; it stays unreachable unless a host opens the firewall.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    pciutils
    usbutils
  ];

  system.stateVersion = "26.11";
}
