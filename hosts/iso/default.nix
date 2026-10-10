# The plain NixOS minimal installer, built from this flake's nixpkgs: the
# same thing as the official ISO from nixos.org (either works for the
# install). Everything else comes from the repo, cloned on the ISO:
# scripts/install-base.
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
}
