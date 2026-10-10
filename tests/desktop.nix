# Headless NixOS test of the desktop, run by `nix flake check`.
{
  pkgs,
  self,
  inputs,
  homeArgs,
}:
pkgs.testers.runNixOSTest {
  name = "desktop";
  node.specialArgs = { inherit inputs self homeArgs; };
  nodes.machine = {
    imports = [
      ../nixos
      ../hosts/vm
    ];
  };
  testScript = ''
    start_all()

    with subtest("base system and sops password"):
        machine.wait_for_unit("multi-user.target")
        machine.succeed("test -s /run/secrets-for-users/user-password")
        machine.succeed("test \"$(id -u jantrojak)\" = 1001")
        machine.succeed("getent passwd jantrojak | grep -q /zsh$")

    with subtest("login with the sops password on tty1"):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("jantrojak\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("vm\n")
        machine.wait_until_succeeds("pgrep -u jantrojak zsh")
  '';
}
