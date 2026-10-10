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

  desktop = import ../tests/desktop.nix {
    inherit
      pkgs
      self
      inputs
      homeArgs
      ;
  };
}
