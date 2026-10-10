# Ubuntu only: recommended for non-NixOS Linux (NIX_PATH, TERMINFO_DIRS,
# XDG data dirs). NixOS must not import this.
{
  targets.genericLinux.enable = true;
}
