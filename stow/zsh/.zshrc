export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
CASE_SENSITIVE="true"
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_AUTO_TITLE="true"
# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE

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
    zsh-syntax-highlighting
    copybuffer   # ctrl-o
    copyfile
    )

fpath=(~/.zfunc ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src $fpath)
autoload -Uz compinit && compinit
mkdir -p ~/.zfunc

source $ZSH/oh-my-zsh.sh
export TERM=xterm-256color

setopt PROMPT_SUBST
RPROMPT='$(kube_ps1)'
export EDITOR=nvim
export VISUAL=nvim
# editors / openers
alias vs='code .'
alias vim='nvim'
alias vvim='command vim'
alias lg='lazygit'
alias x='xdg-open '
# shortcuts
alias g='git '
alias t='tmux '
alias k='kubectl '
alias py='python3 -q '
alias copy='wl-copy'
alias cat='bat'
alias ccat='/usr/bin/cat'
alias -g J='| jq .'
alias -g Y='| yq .'
# bat with forced syntax (handy for piped stdin where bat can't auto-detect)
alias bYAML='bat -l yaml'      # YAML
alias bJSON='bat -l json'      # JSON
alias bXML='bat -l xml'        # XML
alias bHTML='bat -l html'      # HTML
alias bMD='bat -l md'          # Markdown
alias bLOG='bat -l log'        # logs
alias bDIFF='bat -l diff'      # diffs / patches
alias bSQL='bat -l sql'        # SQL
alias bTOML='bat -l toml'      # TOML
alias bINI='bat -l ini'        # INI / .conf
alias bSH='bat -l bash'        # shell scripts
alias sshi='ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null"'
eval "$(/usr/bin/mise activate zsh)"

# fzf — fuzzy history (Ctrl+R), file search (Ctrl+T), folder cd (Ctrl+F)
[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh
[[ -f /usr/share/fzf/shell/completion.zsh ]] && source /usr/share/fzf/shell/completion.zsh
bindkey '^F' fzf-cd-widget

# Edit current command line in nvim (Ctrl+X E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# pager settings — bat for man pages, less elsewhere with ANSI color support
export LESS="-FRX"
export GROFF_NO_SGR=1
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PATH="${HOME}/.krew/bin:$PATH"
# User bins + CLI-name shims (e.g. bat->batcat, fd->fdfind) live in ~/.local/bin.
# Fedora puts it on PATH by default; fresh Ubuntu+zsh does not, so add it here.
# Guarded so it never double-adds where it is already present.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
export LIBVIRT_DEFAULT_URI='qemu:///system'

# ssh-agent (systemd user service) — socket lives under $XDG_RUNTIME_DIR.
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"
export SSH_ASKPASS="${SSH_ASKPASS:-/usr/libexec/openssh/gnome-ssh-askpass}"
export SSH_ASKPASS_REQUIRE=prefer

alias rclaude='CLAUDE_CONFIG_DIR="$HOME/.claude-recombee" claude'

# bash-style completions (mc, aws)
autoload -U +X bashcompinit && bashcompinit
command -v mc &>/dev/null && complete -o nospace -C "$(command -v mc)" mc
command -v aws_completer &>/dev/null && complete -C "$(command -v aws_completer)" aws
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
# Auto-detect and source gcloud autocompletion from your active mise path
if [ -d "$HOME/.local/share/mise/installs/gcloud" ]; then
    source "$(gcloud info --format="value(installation.sdk_root)")/completion.zsh.inc" 2>/dev/null
fi



gwc() {
  if [ -z "$1" ]; then
    echo "Použití: git-wt-clone <url-repozitare> [nazev-slozky]"
    return 1
  fi

  local repo_url="$1"
  local dir_name="$2"

  # Pokud název složky nebyl zadaný, odvodíme ho z URL (např. 'muj-projekt' z '.../muj-projekt.git')
  if [ -z "$dir_name" ]; then
    dir_name=$(basename "$repo_url" .git)
  fi

  local target_dir="${dir_name}.wt"

  echo "Vytvářím worktree strukturu v adresáři: $target_dir"

  mkdir -p "$target_dir/.git" || return 1
  
  # Klonování přímo do .git vnořeného v cílové složce
  git clone --bare "$repo_url" "$target_dir/.git" || return 1

  # Nastavení v novém kontextu
  (
    cd "$target_dir" || exit 1
    git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git fetch origin

    # Zjištění výchozí větve na remote (fallback na 'main')
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [ -z "$default_branch" ]; then
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            default_branch="main"
        else
            default_branch="master"
        fi
    fi

    git symbolic-ref HEAD "refs/heads/$default_branch"
    
    # Vytvoření prvního worktree pro hlavní větev
    git worktree add "$default_branch" "$default_branch"
    
    echo "Hotovo! Vytvořen worktree pro větev '$default_branch' v adresáři ./$target_dir/$default_branch"
  )
}
