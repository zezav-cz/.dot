# Links stow/ packages into ~ like GNU stow does, but via home-manager:
# mkOutOfStoreSymlink points at the working copy (dotfiles.root), so edits
# apply without a rebuild. Off by default: on Ubuntu stow still owns ~.
{ config, lib, ... }:
let
  cfg = config.dotfiles;
  lists = import ./dotfiles-packages.nix;
  stowDir = ../stow;

  # Only packages that exist in this checkout (an untracked package is
  # invisible to the flake and has nothing to link).
  present = builtins.attrNames (builtins.readDir stowDir);
  packages = builtins.filter (p: lib.elem p present) (lists.folded ++ lists.noFolding);

  # Directories home-manager itself writes into (environment.d/10-home-manager.conf,
  # systemd/user/tray.target); link their files, not them. New units there need
  # a rebuild to show up.
  perFileDirs = [
    "systemd/.config/environment.d"
    "systemd/.config/systemd"
  ];

  filesOf =
    pkg:
    map (p: lib.removePrefix "${toString stowDir}/${pkg}/" (toString p)) (
      lib.filesystem.listFilesRecursive (stowDir + "/${pkg}")
    );

  # stow-style folding: ~/.config/<x> and other top-level entries become one
  # link each; files directly in ~/.config stay files.
  foldedUnit =
    pkg: f:
    let
      parts = lib.splitString "/" f;
      top = builtins.head parts;
      second = builtins.elemAt parts 1;
    in
    if top == ".config" && builtins.length parts > 2 then
      (if lib.elem "${pkg}/.config/${second}" perFileDirs then f else ".config/${second}")
    else if top != ".config" && builtins.length parts > 1 then
      top
    else
      f;

  unitsOf =
    pkg:
    if lib.elem pkg lists.noFolding then
      filesOf pkg
    else
      lib.unique (map (foldedUnit pkg) (filesOf pkg));

  linksOf =
    pkg:
    lib.listToAttrs (
      map (u: {
        name = u;
        value.source = config.lib.file.mkOutOfStoreSymlink "${cfg.root}/stow/${pkg}/${u}";
      }) (unitsOf pkg)
    );
in
{
  options.dotfiles = {
    enable = lib.mkEnableOption "linking stow/ packages into ~ with home-manager";
    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.dot";
      description = "Working copy of this repo the links point into.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge (map linksOf packages);

    # gpg refuses a group/world-readable ~/.gnupg; per-file links leave the
    # directory itself to home-manager, which creates it 0755.
    home.activation.gnupgPermissions = lib.mkIf (lib.elem "gnupg" packages) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run chmod 700 "$HOME/.gnupg"
      ''
    );
  };
}
