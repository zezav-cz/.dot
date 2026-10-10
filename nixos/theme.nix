# stylix only where nothing in stow/ already themes at runtime: the Linux
# console and fontconfig defaults. GTK/Qt, foot, nvim, k9s, waybar follow the
# color-scheme toggle in stow/sway/.config/waybar/scripts/colorscheme.sh, and
# stylix must not fight it.
{ inputs, pkgs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = {
    enable = true;
    autoEnable = false;
    homeManagerIntegration.autoImport = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    polarity = "dark";
    fonts.monospace = {
      package = pkgs.nerd-fonts.meslo-lg;
      name = "MesloLGS Nerd Font Mono";
    };
    targets = {
      console.enable = true;
      fontconfig.enable = true;
    };
  };
}
