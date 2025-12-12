#!/bin/bash
set -e

info() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }

install_mise() {
    info "Installing mise..."
    which mise &> /dev/null && {
        info "mise is already installed. Skipping installation."
        return
    }
    set -x
    sudo dnf copr enable jdxcode/mise -y
    sudo dnf install mise -y
    set +x
    info "mise installed successfully."
}
add_repos() {
    info "Adding necessary repositories..."
    sudo dnf install -y dnf-plugins-core
    # VScode
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
        | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    info "Repositories added successfully."
}
install_basics() {
    info "Installing basic dependencies..."
    sudo dnf install -y \
        git \
        wget \
        curl \
        vim \
        neovim \
        stow \
        code
    info "Basic dependencies installed successfully."
}
download_fonts() {
    info "Downloading and installing fonts..."
    
    mkdir -p fonts
    if [ -f fonts/Meslo.zip ]; then
        info "Fonts Meslo.zip already exists. Skipping download."
    else
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip -O fonts/Meslo.zip
        mkdir -p fonts/nerd-fonts/
        unzip fonts/Meslo.zip -d fonts/nerd-fonts/
    fi
    info "Fonts downloaded successfully."
}
install_oh_my_zsh() {
    info "Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh is already installed. Skipping installation."
        return
    fi
    if ! command -v zsh &> /dev/null; then
        info "Zsh is not installed. Installing zsh first."
        sudo dnf install -y zsh
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        info "zsh-syntax-highlighting plugin already exists. Pulling latest."
        git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" pull
    else
        info "Cloning zsh-syntax-highlighting plugin."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    info "Oh My Zsh installed successfully."
}
stow_configs() {
    info "Stowing configuration files..."
    stow foot
    stow git
    # stow nvim
    # stow sway
    # stow systemd

    # ZSH
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    fi
    stow zsh

}
main() {
    info "Starting installatoin"
    add_repos
    install_basics
    install_mise
    download_fonts
    install_oh_my_zsh
    stow_configs
}

cd $(dirname "$0")
main "$@"
cd -
