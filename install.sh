#!/bin/bash
set -e

info() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }



install() {
    install_repos() {
    local vscode_repo=$(cat <<EOF
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
        sudo dnf install -y dnf-plugins-core
        sudo dnf copr enable tofik/nwg-shell -y
        sudo dnf copr enable alternateved/cliphist -y
        sudo dnf copr enable jdxcode/mise -y
        sudo dnf copr enable che/nerd-fonts -y
        # VScode
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        echo -e "$vscode_repo" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    }

    # Install packages
    install_packages() {
        sudo dnf install -y \
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
        wget https://slack.com/downloads/instructions/linux?ddl=1&build=rpm
    }

    # oh-my-zsh
    install_oh_my_zsh() {
        if [ -d "$HOME/.oh-my-zsh" ]; then
            info "Oh My Zsh is already installed. Skipping installation."
        else
            info "Cloning Oh My Zsh repository."
            if ! command -v zsh &> /dev/null; then
                info "Zsh is not installed. Installing zsh first."
                sudo dnf install -y zsh
            fi
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        fi
        if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
            info "zsh-syntax-highlighting plugin already exists. Pulling latest."
            git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" pull
        else
            info "Cloning zsh-syntax-highlighting plugin."
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
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
        sudo wget -q "$obsidian_url" -O /usr/local/bin/obsidian
        info "Installing Obsidian version $version into /usr/local/bin/obsidian"
        sudo chmod +x /usr/local/bin/obsidian
    }

    install_telegram() {
        info "Installing Telegram Desktop..."
        wget -q https://telegram.org/dl/desktop/linux -O /tmp/telegram.tar.xz
        tar -xf /tmp/telegram.tar.xz -C /tmp/
        sudo mv /tmp/Telegram/* /usr/local/bin/
    }

    info "Installing basic packages..."
    install_repos
    info "Inserting packages..."
    install_packages
    info "Installing oh-my-zsh..."
    install_oh_my_zsh
    info "Inserting Obsidian..."
    install_obsidian "1.10.6"
    info "Inserting Telegram..."
    # install_telegram


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

download_and_install_fonts() {
    local install_dir="$HOME/.local/share/fonts"
    info "Downloading and installing fonts..."

    mkdir -p "$install_dir"
    if [ -f "$install_dir/Meslo.zip" ]; then
        info "Fonts Meslo.zip already exists. Skipping download."
    else
        info "Downloading Meslo Nerd Font."
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip -O "$install_dir/Meslo.zip"
        mkdir -p "$install_dir/nerd-fonts/"
        unzip "$install_dir/Meslo.zip" -d "$install_dir/nerd-fonts/"
    fi

    if [ -f "$install_dir/fontawesome-6-console.zip" ]; then
        info "Font Awesome Console font already exists. Skipping download."
    else
        info "Downloading Font Awesome Console font."
        wget https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip -O "$install_dir/fontawesome-6-console.zip"
        mkdir -p "$install_dir/fontawesome-6-console/"
        unzip "$install_dir/fontawesome-6-console.zip" -d "$install_dir/fontawesome-6-console/"
    fi


    fc-cache -f
    info "Fonts downloaded successfully."
}

stow_configs() {
    info "Stowing configuration files..."
    # stow foot # fails
    set -x
    stow git
    stow mise
    stow my-scripts --no-folding
    stow nvim
    stow rofi
    stow sway
    stow syncing --no-folding
    stow systemd

    # ZSH
    set +x
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        set -x ;rm "$HOME/.zshrc" ; set +x
    fi
    set -x ; stow zsh ;set +x

}


set_up_vnotes() {
    info "Setting up VNotes..."
    local vnotes_dir="$HOME/VNotes"
    if [ -d "$vnotes_dir/.git" ]; then
        info "VNotes repository already exists. Pulling latest changes."
        git -C "$vnotes_dir" pull
        return 0
    fi
    git clone git@github.com:zezav-cz/vnotes.git "$vnotes_dir"
    info "VNotes set up successfully."
}

main() {
    info "Starting installatoin"
    install
    info "Installing fonts"
    install_fonts "Meslo"
    # download_and_install_fonts
    stow_configs
    set_up_vnotes
}

cd $(dirname "$0")
main "$@"
cd -
