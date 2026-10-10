{ inputs, homeArgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    # false: packages go to ~/.nix-profile exactly like on Ubuntu, which
    # .zshrc's fpath and plantuml-server.service (%h/.nix-profile/bin) expect.
    useUserPackages = false;
    extraSpecialArgs = homeArgs;
    backupFileExtension = "hm-backup";
    users.jantrojak = {
      imports = [ ../home ];
      dotfiles.enable = true;
    };
  };
}
