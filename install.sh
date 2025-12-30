#!/bin/bash
set -euo pipefail

# Configuration
OBSIDIAN_VERSION="1.10.6"
NERD_FONTS="Meslo"

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GREY=$'\033[90m'
RESET=$'\033[0m'

info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }

run() {
    "$@" 2>&1 | sed "s/^/   ${GREY}/;s/$/${RESET}/"
}

install() {
    install_repos() {
    local vscode_repo
    vscode_repo=$(cat <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
)
        run sudo dnf install -y dnf-plugins-core
        run sudo dnf copr enable tofik/nwg-shell -y
        run sudo dnf copr enable alternateved/cliphist -y
        run sudo dnf copr enable jdxcode/mise -y
        run sudo dnf copr enable che/nerd-fonts -y
        # VScode
        run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        echo -e "$vscode_repo" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    }

    # Install packages
    install_packages() {
        run sudo dnf install -y \
            git tig \
            ruby ruby-devel golang mise \
            wget curl code \
            vim neovim \
            stow \
            podman \
            rofimoji  grim slurp swappy wl-clipboard geoclue2 gammastep \
            nwg-bar nwg-displays \
            fuse fuse-libs \
            cliphist \
            nerd-fonts \
            git-core zlib-devel libffi-devel readline-devel openssl-devel \
                make gcc patch autoconf automake bison libtool sqlite-devel \
            cockpit-image-builder.noarch cockpit-packagekit.noarch \
                cockpit-podman.noarch cockpit-selinux.noarch \
                cockpit-storaged.noarch  cockpit-networkmanager pcp python3-pcp
    }

    # oh-my-zsh
    install_oh_my_zsh() {
        if [ -d "$HOME/.oh-my-zsh" ]; then
            info "Oh My Zsh is already installed. Skipping installation."
        else
            info "Cloning Oh My Zsh repository."
            if ! command -v zsh &> /dev/null; then
                info "Zsh is not installed. Installing zsh first."
                run sudo dnf install -y zsh
            fi
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
        if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
            info "zsh-autosuggestions plugin already exists. Pulling latest."
            run git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" pull
        else
            info "Cloning zsh-autosuggestions plugin."
            run git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        fi
    }

    install_obsidian() {
        info "Installing Obsidian..."
        which obsidian &> /dev/null && {
            info "Obsidian is already installed. Skipping installation."
            return
        }
        if [ -z "$1" ]; then
            error "No version specified for Obsidian installation."
            return 1
        fi
        local version=$1
        local obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v$version/Obsidian-$version.AppImage"
        info "Downloading Obsidian version $version from $obsidian_url"
        if ! sudo wget -q "$obsidian_url" -O /usr/local/bin/obsidian; then
            error "Failed to download Obsidian from $obsidian_url"
            return 1
        fi
        info "Setting executable permissions for Obsidian"
        sudo chmod +x /usr/local/bin/obsidian
    }

    # install_telegram() {
    #     info "Installing Telegram Desktop..."
    #     wget -q https://telegram.org/dl/desktop/linux -O /tmp/telegram.tar.xz
    #     tar -xf /tmp/telegram.tar.xz -C /tmp/
    #     sudo mv /tmp/Telegram/* /usr/local/bin/
    # }

    info "Installing basic packages..."
    install_repos
    info "Installing packages..."
    install_packages
    info "Installing oh-my-zsh..."
    install_oh_my_zsh
    info "Installing Obsidian..."
    install_obsidian "$OBSIDIAN_VERSION"
}

install_fonts() {
    local install_dir="$HOME/.local/share/fonts/nerd-fonts"
    info "Installing Nerd Fonts..."

    if [ $# -eq 0 ]; then
        warning "No fonts specified. Skipping font installation."
        return 0
    fi

    mkdir -p "$install_dir"

    for font_name in "$@"; do
        local zip_file="$install_dir/${font_name}.zip"
        local font_dir="$install_dir/${font_name}"

        if [ -d "$font_dir" ]; then
            info "Font $font_name is already installed. Skipping."
            continue
        fi

        info "Downloading Nerd Font: $font_name"
        local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"

        if wget -q "$download_url" -O "$zip_file"; then
            info "Installing $font_name to $font_dir"
            mkdir -p "$font_dir"
            unzip -q "$zip_file" -d "$font_dir"
            rm "$zip_file"
            info "Successfully installed $font_name"
        else
            error "Failed to download $font_name from $download_url"
            [ -f "$zip_file" ] && rm "$zip_file"
        fi
    done

    info "Updating font cache..."
    fc-cache -f
    info "Font installation completed."
}

stow_configs() {
    info "Stowing configuration files..."
    run stow git -v
    run stow mise -v
    run stow my-scripts --no-folding -v
    run stow nvim -v
    run stow rofi -v
    run stow sway -v
    run stow syncing --no-folding -v
    run stow systemd -v

    # ZSH
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    fi
    run stow zsh -v
}

set_up_systemd() {
    info "Setting up systemd services..."
    systemctl --user enable git-autopush-vnotes.timer
}

set_up_vnotes() {
    info "Setting up VNotes..."
    local vnotes_dir="$HOME/vnotes"
    if [ -d "$vnotes_dir/.git" ]; then
        info "VNotes repository already exists. Pulling latest changes."
        run git -C "$vnotes_dir" pull
        return 0
    fi
    run git clone git@github.com:zezav-cz/vnotes.git "$vnotes_dir"
    info "VNotes set up successfully."
}

main() {
    info "Starting installation"
    install
    info "Installing fonts"
    install_fonts "$NERD_FONTS"
    stow_configs
    set_up_vnotes
    set_up_systemd
}

cd "$(dirname "$0")"
main "$@"
cd - > /dev/null
