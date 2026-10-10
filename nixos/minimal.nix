# The part of nixos/ every stage needs: nix, locale, network, sshd, sops and
# the user. Stage 1 of the install (p15v-base) is only this; nixos/default.nix
# adds the desktop and home-manager on top.
{
  imports = [
    ./base.nix
    ./secrets.nix
    ./users.nix
  ];
}
