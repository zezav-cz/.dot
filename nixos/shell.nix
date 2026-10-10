# Replaces ansible/roles/shell (git clones of oh-my-zsh + plugins). The stowed
# .zshrc reads $ZSH/$ZSH_CUSTOM when set and falls back to ~/.oh-my-zsh on
# Ubuntu.
{ pkgs, ... }:
let
  omzCustom = pkgs.runCommand "oh-my-zsh-custom" { } ''
    mkdir -p $out/plugins/zsh-autosuggestions $out/plugins/zsh-syntax-highlighting $out/plugins/zsh-completions
    echo "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
      > $out/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    echo "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
      > $out/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
    ln -s ${pkgs.zsh-completions}/share/zsh/site-functions $out/plugins/zsh-completions/src
  '';
in
{
  programs.zsh = {
    enable = true;
    # .zshrc runs compinit itself; a second global one only slows startup.
    enableGlobalCompInit = false;
  };

  environment.variables = {
    ZSH = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
    ZSH_CUSTOM = "${omzCustom}";
    # $ZSH is read-only in the store
    ZSH_CACHE_DIR = "$HOME/.cache/oh-my-zsh";
    DISABLE_AUTO_UPDATE = "true";
  };

  # Replaces installer/steps/s10_direnv.py (~/.config/direnv/direnvrc).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    fzf
    tmux
  ];
}
