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
      # No GPU in the test VM: software rendering.
      virtualisation.qemu.options = [
        "-vga none"
        "-device virtio-gpu-pci"
      ];
      environment.sessionVariables = {
        WLR_RENDERER = "pixman";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
    };
  testScript = ''
    start_all()

    with subtest("base system and sops password"):
        machine.wait_for_unit("multi-user.target")
        machine.succeed("test -s /run/secrets-for-users/user-password")
        machine.succeed("test \"$(id -u jantrojak)\" = 1001")
        machine.succeed("getent passwd jantrojak | grep -q /zsh$")

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

    def user(cmd):
        return ("runuser -u jantrojak -- env XDG_RUNTIME_DIR=/run/user/1001 "
                "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus "
                f"sh -c 'SWAYSOCK=$(ls /run/user/1001/sway-ipc.*.sock 2>/dev/null | head -1); export SWAYSOCK; {cmd}'")

    with subtest("greetd login with the sops password starts sway"):
        machine.wait_for_unit("greetd.service")
        machine.wait_until_tty_matches("1", "Username")
        machine.send_chars("jantrojak\n")
        machine.wait_until_tty_matches("1", "Password")
        machine.send_chars("vm\n")
        machine.wait_until_succeeds("ls /run/user/1001/sway-ipc.*.sock", timeout=120)
        machine.succeed(user("swaymsg -t get_tree >/dev/null"))
        # config parses: a reload succeeds and sway raises no swaynag
        machine.succeed(user("swaymsg reload"))  # exits non-zero when the reload fails
        machine.sleep(2)
        machine.fail("pgrep -x swaynag")

    with subtest("session units"):
        for unit in ["sway-session.target", "waybar.service", "swaync.service", "kanshi.service", "ssh-agent.service"]:
            machine.wait_until_succeeds(user(f"systemctl --user is-active {unit}"), timeout=60)
        machine.succeed(user("systemctl --user is-active timers.target"))
        machine.succeed(user("systemctl --user list-timers --all | grep -q battery-notify"))
        machine.wait_until_succeeds(user("systemctl --user is-active xdg-desktop-portal.service"), timeout=60)
        machine.succeed("test -e /etc/pam.d/swaylock")

    with subtest("every binary the sway config calls exists"):
        machine.succeed(user(
            "for c in waybar swaync swaylock swayidle kanshi rofi foot grim slurp grimshot swappy "
            "wl-copy wl-paste cliphist gammastep brightnessctl playerctl pactl notify-send "
            "xdg-user-dirs-update nwg-bar gsettings lxqt-openssh-askpass; do "
            "command -v $c >/dev/null || { echo missing $c; exit 1; }; done"))

    with subtest("swaymsg reload keeps the session"):
        machine.succeed(user("swaymsg reload"))
        machine.sleep(5)
        for unit in ["sway-session.target", "waybar.service", "kanshi.service"]:
            machine.wait_until_succeeds(user(f"systemctl --user is-active {unit}"), timeout=60)
        machine.screenshot("desktop")
  '';
}
