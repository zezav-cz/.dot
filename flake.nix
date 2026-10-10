{
  description = "p15v: NixOS system and home-manager user environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Bazel 9.0.1 only: unstable's bazel_9 has moved on to 9.1.1 and there is
    # no 9.0.x attribute left, so the version is pinned by pinning the nixpkgs
    # revision that last shipped it. Bump this rev (not the version) if 9.0.1
    # ever needs a rebuild against newer deps.
    nixpkgs-bazel.url = "github:NixOS/nixpkgs/01fbdeef22b76df85ea168fbfe1bfd9e63681b30";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # private repo, has its own flake.nix (packages.default via buildGoModule)
    vn = {
      url = "git+ssh://git@github.com/zezav-cz/vn.git?ref=refs/tags/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      inherit (nixpkgs) lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # slack, obsidian, nvidia, etc.
      };
      homeArgs = import ./home/args.nix { inherit pkgs inputs; };
      # Every host shares nixos/ and the one pkgs instance above.
      mkHost =
        modules:
        lib.nixosSystem {
          specialArgs = { inherit inputs self homeArgs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./nixos
          ]
          ++ modules;
        };
    in
    {
      homeConfigurations."jantrojak" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = homeArgs;
        modules = [
          ./home
          ./home/generic-linux.nix
        ];
      };

      nixosConfigurations = {
        vm = mkHost [
          ./hosts/vm
          ./hosts/vm/interactive.nix
        ];
      };

      checks.${system} = import ./checks {
        inherit
          pkgs
          self
          inputs
          homeArgs
          ;
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
