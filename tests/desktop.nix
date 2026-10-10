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
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        ../nixos
        ../hosts/vm
      ];
      # Resolve the out-of-store links against the repo copy in the store.
      home-manager.users.jantrojak.dotfiles.root = lib.mkForce "${self}";
      environment.etc."dotfiles-root".text = "${self}";
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

    with subtest("home-manager links dotfiles out of store"):
        machine.wait_for_unit("home-manager-jantrojak.service")
        root = machine.succeed("cat /etc/dotfiles-root").strip()
        # folded package: the whole directory is one link into the repo
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.config/sway)\" = {root}/stow/sway/.config/sway")
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.zshrc)\" = {root}/stow/zsh/.zshrc")
        # no-folding package: real directory, per-file links
        machine.succeed("test -d /home/jantrojak/.config/foot -a ! -L /home/jantrojak/.config/foot")
        machine.succeed(f"test \"$(readlink -f /home/jantrojak/.config/foot/foot.ini)\" = {root}/stow/foot/.config/foot/foot.ini")
        machine.succeed("test \"$(stat -c %a /home/jantrojak/.gnupg)\" = 700")

    with subtest("runtime-written files stay out of the repo"):
        for f in [".config/foot/runtime-state", ".config/k9s/runtime-state", ".config/lazygit/state.yml", ".gnupg/pubring.kbx"]:
            machine.succeed(f"su jantrojak -c 'echo x > /home/jantrojak/{f}'")
            machine.succeed(f"test ! -L /home/jantrojak/{f}")
            machine.succeed(f"case \"$(readlink -f /home/jantrojak/{f})\" in {root}/*) exit 1;; esac")

    with subtest("interactive zsh starts clean"):
        out = machine.succeed("su - jantrojak -c \"zsh -ic 'echo ok' 2>&1\"").strip()
        assert out == "ok", f"zsh printed extra output:\n{out}"
        machine.succeed("su - jantrojak -c \"zsh -ic 'type _zsh_autosuggest_start && (( \\''${+functions[_zsh_highlight]} ))'\"")
  '';
}
