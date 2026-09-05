{
  description = "home-manager config mirroring global mise tools (stow/mise/.config/mise/config.toml)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # private repo, has its own flake.nix (packages.default via buildGoModule)
    vn = {
      url = "git+ssh://git@github.com/zezav-cz/vn.git?ref=refs/tags/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # slack, obsidian, etc.
      };
    in {
      homeConfigurations."jantrojak" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          ccstatusline = pkgs.callPackage ./nix/ccstatusline.nix { };
          jira-cli = pkgs.callPackage ./nix/jira-cli.nix { };
          claude-desktop = pkgs.callPackage ./nix/claude-desktop.nix { };
        };
        modules = [ ./home.nix ];
      };
    };
}
