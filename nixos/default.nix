# Shared by every machine (vm, p15v, p15v-rehearsal). Host differences live
# in hosts/. One module per former ansible role.
{
  imports = [
    ./base.nix
    ./secrets.nix
    ./users.nix
    ./home.nix
    ./shell.nix
  ];
}
