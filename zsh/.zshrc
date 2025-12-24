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
    )


source $ZSH/oh-my-zsh.sh
export TERM=xterm-256color

alias vs='code ./'
alias py='python3 -q '
alias x='xdg-open '

eval "$(/usr/bin/mise activate zsh)"
