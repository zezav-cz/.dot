{ lib, inputs, ... }:
{
  system.extraDependencies = import ../lib/flake-sources.nix { inherit lib inputs; };
}
