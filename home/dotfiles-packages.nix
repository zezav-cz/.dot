# Mirrors STOW_PACKAGES / STOW_NO_FOLDING in installer/config.py (checked by
# checks.dotfiles-parity until the Ubuntu installer is removed).
{
  # Linked as whole directories (stow "folding"): editing or adding files
  # under them needs no rebuild.
  folded = [
    "ccstatusline"
    "git"
    "mise"
    "nvim"
    "rofi"
    "ssh-agent"
    "sway"
    "systemd"
    "tmux"
    "zsh"
    "nwg-displays"
    "xdg-portals"
  ];
  # Linked per file: the target directory also holds runtime state that must
  # stay outside the repo (see the comments on STOW_NO_FOLDING).
  noFolding = [
    "claude"
    "claude-personal"
    "gnupg"
    "my-scripts"
    "pgcli"
    "vscode"
    "foot"
    "k9s"
    "lazygit"
    "lnav"
    "pandoc"
  ];
}
