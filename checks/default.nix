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

  desktop = import ../tests/desktop.nix {
    inherit
      pkgs
      self
      inputs
      homeArgs
      ;
  };
}
