# extraSpecialArgs for the user environment, shared by the standalone
# (Ubuntu) homeConfigurations and the NixOS home-manager module.
{ pkgs, inputs }:
{
  inherit inputs;
  ccstatusline = pkgs.callPackage ../nix/ccstatusline.nix { };
  jira-cli = pkgs.callPackage ../nix/jira-cli.nix { };
  claude-desktop = pkgs.callPackage ../nix/claude-desktop.nix { };
}
