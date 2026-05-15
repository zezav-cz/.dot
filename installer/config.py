"""All declarations: packages, repos, fonts, app versions, stow targets."""

from dataclasses import dataclass
from pathlib import Path

# ──────────────────────────────────────────────
# Paths
# ──────────────────────────────────────────────
HOME = Path.home()
DOTFILES_DIR = Path(__file__).resolve().parent.parent  # .dot/
FONTS_DIR = HOME / ".local" / "share" / "fonts"
NERD_FONTS_DIR = FONTS_DIR / "nerd-fonts"

# ──────────────────────────────────────────────
# Repos (Fedora-specific)
# ──────────────────────────────────────────────
COPR_REPOS = [
    "tofik/nwg-shell",
    "alternateved/cliphist",
    "jdxcode/mise",
    "che/nerd-fonts",
    "g3tchoo/prismlauncher",
]

VSCODE_REPO = """\
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"""

# ──────────────────────────────────────────────
# Packages (per distro)
# ──────────────────────────────────────────────
PACKAGES = {
    "fedora": [
        # VCS & tools
        "git",
        "tig",
        # Languages & build
        "ruby",
        "ruby-devel",
        "golang",
        "mise",
        "cmake",
        # CLI utils
        "wget",
        "curl",
        "code",
        # Editors
        "vim",
        "neovim",
        # Dotfile management
        "stow",
        # Containers
        "podman",
        # Sway / Wayland utilities
        "rofimoji",
        "grim",
        "slurp",
        "swappy",
        "wl-clipboard",
        "geoclue2",
        "gammastep",
        "nwg-bar",
        "nwg-displays",
        # FUSE (for AppImages)
        "fuse",
        "fuse-libs",
        # Clipboard
        "cliphist",
        # SSH
        "openssh-askpass",
        # Fonts
        "nerd-fonts",
        # Build dependencies
        "git-core",
        "zlib-devel",
        "libffi-devel",
        "readline-devel",
        "openssl-devel",
        "make",
        "gcc",
        "patch",
        "autoconf",
        "automake",
        "bison",
        "libtool",
        "sqlite-devel",
        "libyaml-devel",
        # Cockpit
        "cockpit-image-builder.noarch",
        "cockpit-packagekit.noarch",
        "cockpit-podman.noarch",
        "cockpit-selinux.noarch",
        "cockpit-storaged.noarch",
        "cockpit-networkmanager",
        "pcp",
        "python3-pcp",
        # Misc
        "dbus-glib",
        # Games
        "prismlauncher",
    ],
    "debian": [
        # TODO: map Fedora package names to Debian equivalents where they differ
        # e.g. ruby-devel -> ruby-dev, zlib-devel -> zlib1g-dev, neovim -> neovim,
        #      openssl-devel -> libssl-dev, readline-devel -> libreadline-dev
        "git",
        "tig",
        "ruby",
        "golang",
        "cmake",
        "wget",
        "curl",
        "vim",
        "neovim",
        "stow",
        "podman",
        "grim",
        "slurp",
        "wl-clipboard",
        "gammastep",
        "fuse3",
        "make",
        "gcc",
        "patch",
        "autoconf",
        "automake",
        "bison",
        "libtool",
    ],
    "arch": [
        # TODO: map Fedora package names to Arch equivalents where they differ
        # e.g. ruby-devel -> (included in ruby), neovim -> neovim,
        #      fuse-libs -> fuse3, code -> code (AUR)
        "git",
        "tig",
        "ruby",
        "go",
        "cmake",
        "wget",
        "curl",
        "vim",
        "neovim",
        "stow",
        "podman",
        "grim",
        "slurp",
        "wl-clipboard",
        "gammastep",
        "fuse3",
        "make",
        "gcc",
        "patch",
        "autoconf",
        "automake",
        "bison",
        "libtool",
    ],
}

# ──────────────────────────────────────────────
# Fonts
# ──────────────────────────────────────────────
NERD_FONTS_VERSION = "v3.4.0"


@dataclass
class FontDownload:
    name: str
    url: str
    zip_name: str  # saved as <FONTS_DIR>/<zip_name>
    extract_dir: str  # extracted to <FONTS_DIR>/<extract_dir>/


EXTRA_FONTS = [
    FontDownload(
        name="Meslo Nerd Font",
        url=f"https://github.com/ryanoasis/nerd-fonts/releases/download/{NERD_FONTS_VERSION}/Meslo.zip",
        zip_name="Meslo.zip",
        extract_dir="nerd-fonts",
    ),
    FontDownload(
        name="Font Awesome 6 Console",
        url="https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip",
        zip_name="fontawesome-6-console.zip",
        extract_dir="fontawesome-6-console",
    ),
]


# ──────────────────────────────────────────────
# Apps (AppImage / manual installs)
# ──────────────────────────────────────────────
@dataclass
class AppInstall:
    name: str
    version: str
    url_template: str  # use {version} placeholder
    install_path: str  # absolute destination path


APPS_OBSIDIAN = AppInstall(
    name="obsidian",
    version="1.10.6",
    url_template="https://github.com/obsidianmd/obsidian-releases/releases/download/v{version}/Obsidian-{version}.AppImage",
    install_path="/usr/local/bin/obsidian",
)

# ──────────────────────────────────────────────
# oh-my-zsh
# ──────────────────────────────────────────────
ZSH_CUSTOM = Path(f"{HOME}/.oh-my-zsh/custom")
ZSH_PLUGINS = {
    "zsh-autosuggestions": "https://github.com/zsh-users/zsh-autosuggestions",
    "zsh-syntax-highlighting": "https://github.com/zsh-users/zsh-syntax-highlighting",
}

# ──────────────────────────────────────────────
# Stow
# ──────────────────────────────────────────────
STOW_PACKAGES = [
    "git",
    "mise",
    "nvim",
    "rofi",
    "ssh-agent",
    "sway",
    "systemd",
    "tmux",
    "zsh",
    "foot",
    "k9s",
    "nwg-displays",
]
STOW_NO_FOLDING = ["my-scripts", "pgcli"]

# ──────────────────────────────────────────────
# VNotes
# ──────────────────────────────────────────────
VNOTES_DIR = HOME / "VNotes"
VNOTES_REPO = "git@github.com:zezav-cz/vnotes.git"
