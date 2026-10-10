# The user environment. Imported by NixOS (nixos/home.nix) and by the
# standalone Ubuntu homeConfigurations (flake.nix, together with
# ./generic-linux.nix).
_: {
  imports = [
    ./packages.nix
    ./dotfiles.nix
  ];

  home.username = "jantrojak";
  home.homeDirectory = "/home/jantrojak";

  # Bumping this after the initial setup is not required/recommended;
  # it pins the home-manager config format, not package versions.
  home.stateVersion = "24.11";

  home.sessionVariables = {
    GOPRIVATE = "github.com/zezav-cz/*";
  };

  programs.home-manager.enable = true;
}
