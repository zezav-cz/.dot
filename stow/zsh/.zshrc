export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
CASE_SENSITIVE="true"
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_AUTO_TITLE="true"
# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
    git
    zsh-autosuggestions
    kube-ps1
    fluxcd
    helm
    kubectl
    )


source $ZSH/oh-my-zsh.sh
export TERM=xterm-256color

setopt PROMPT_SUBST
RPROMPT='$(kube_ps1)'
alias vs='code ./'
alias py='python3 -q '
alias x='xdg-open '
alias g='git '
alias t='tmux '
alias k='kubectl '

eval "$(/usr/bin/mise activate zsh)"
export PATH="${HOME}/.krew/bin:$PATH"

# ssh-agent (systemd user service) — socket lives under $XDG_RUNTIME_DIR.
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"
export SSH_ASKPASS="${SSH_ASKPASS:-/usr/libexec/openssh/gnome-ssh-askpass}"
export SSH_ASKPASS_REQUIRE=prefer

alias rclaude='CLAUDE_CONFIG_DIR=~/.claude-recombee claude'
