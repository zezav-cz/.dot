# Replaces ansible roles packages-base, sway-minimal and sway-portability.
# The sway/waybar/kanshi configs themselves stay in stow/ (home/dotfiles.nix).
{ pkgs, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # Everything stow/sway calls by name; also lands in systemPackages.
    extraPackages = with pkgs; [
      swaylock
      swayidle
      foot
      waybar
      swaynotificationcenter
      kanshi
      rofi
      grim
      slurp
      sway-contrib.grimshot
      swappy
      wl-clipboard
      cliphist
      gammastep
      brightnessctl
      playerctl
      pulseaudio # pactl
      libnotify # notify-send
      xdg-user-dirs
      nwg-bar
      nwg-displays
      glib # gsettings
      lxqt.lxqt-openssh-askpass # stow/my-scripts/.local/bin/ssh-askpass-portable
      lxsession # lxpolkit, as on Ubuntu (packages-base)
    ];
  };

  # sway-session.target (stow/systemd) Wants= these; on Ubuntu the distro
  # packages ship the units, here the packages do.
  systemd.packages = with pkgs; [
    waybar
    swaynotificationcenter
  ];
  services.dbus.packages = [ pkgs.swaynotificationcenter ];

  # xdg.portal: programs.sway already enables the gtk + wlr portals and routes
  # them like stow/xdg-portals (gtk by default, wlr for ScreenCast/Screenshot).

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;

  # gsettings calls in stow/sway/.config/sway/config and the waybar
  # colour-scheme toggle
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra # Adwaita-dark for GTK3
  ];

  services.tailscale.enable = true; # `tailscale systray` in the sway config
  hardware.bluetooth.enable = true;
}
