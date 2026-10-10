# Replaces ansible/roles/fonts (Meslo Nerd Font + Font Awesome 6 downloads).
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg # "MesloLGS Nerd Font Mono" in foot.ini
    font-awesome_6
    noto-fonts
    noto-fonts-color-emoji # "Noto Color Emoji" in foot.ini
  ];
}
