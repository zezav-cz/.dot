# ThinkPad P15v Gen 1, full desktop. nixos-hardware has no profile for it;
# base.nix composes the common ones.
{
  imports = [
    ./base.nix
    ./nvidia.nix
  ];
}
