# sops-nix. Each host sets sops.defaultSopsFile; every sops file must contain
# `user-password`.
{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
}
