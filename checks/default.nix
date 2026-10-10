{
  pkgs,
  self,
  inputs,
  homeArgs,
}:
{
  nix-lint =
    pkgs.runCommand "nix-lint"
      {
        nativeBuildInputs = [
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
          pkgs.findutils
        ];
      }
      ''
        cd ${self}
        find . -name '*.nix' -not -path './stow/*' -print0 | xargs -0 nixfmt --check
        statix check .
        deadnix --fail --no-lambda-pattern-names .
        touch $out
      '';

  portable-paths = pkgs.runCommand "portable-paths" { nativeBuildInputs = [ pkgs.bash ]; } ''
    bash ${self}/scripts/check-portable-paths ${self}/stow
    touch $out
  '';

  dotfiles-parity = pkgs.runCommand "dotfiles-parity" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${self}/scripts/check-dotfiles-parity ${self}/installer/config.py \
      ${pkgs.writeText "lists.json" (builtins.toJSON (import ../home/dotfiles-packages.nix))}
    touch $out
  '';

  # Facts about the laptop config that must hold before it ever boots.
  p15v-layout =
    let
      c = self.nixosConfigurations.p15v.config;
      inherit (pkgs) lib;
    in
    assert lib.elem "subvol=@home" c.fileSystems."/home".options;
    assert lib.elem "subvol=@nix" c.fileSystems."/nix".options;
    assert c.fileSystems ? "/home/.snapshots";
    assert c.boot.initrd.luks.devices ? cryptroot;
    assert c.boot.initrd.luks.devices.cryptroot.allowDiscards;
    assert c.console.keyMap == "us";
    assert !c.hardware.nvidia.open;
    assert lib.elem "--unsupported-gpu" c.programs.sway.extraOptions;
    assert c.services.snapper.configs ? home;
    # sudo nixos-rebuild evaluates as root, which cannot fetch the private
    # vn input over SSH: its source must stay in the store (a GC root).
    assert lib.elem inputs.vn.outPath (map toString c.system.extraDependencies);
    pkgs.runCommand "p15v-layout" { } "touch $out";

  # Stage 1 of the install: same disk, boot and user as p15v, but no desktop
  # and no home-manager, so it installs fast from the plain NixOS ISO.
  p15v-base-layout =
    let
      base = self.nixosConfigurations.p15v-base.config;
      full = self.nixosConfigurations.p15v.config;
      inherit (pkgs) lib;
      fsOf = c: lib.mapAttrs (_: f: f.options) c.fileSystems;
    in
    assert fsOf base == fsOf full;
    assert base.boot.initrd.luks.devices ? cryptroot;
    assert base.users.users.jantrojak.uid == 1001;
    assert base.sops.defaultSopsFile == full.sops.defaultSopsFile;
    assert base.networking.networkmanager.ensureProfiles.profiles ? home;
    assert lib.elem pkgs.git base.environment.systemPackages;
    assert !base.services.greetd.enable;
    assert !(base ? home-manager);
    pkgs.runCommand "p15v-base-layout" { } "touch $out";

  p15v-toplevel = self.nixosConfigurations.p15v.config.system.build.toplevel;

  desktop = import ../tests/desktop.nix {
    inherit
      pkgs
      self
      inputs
      homeArgs
      ;
  };
}
