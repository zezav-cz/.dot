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
APPIMAGE_DIR = HOME / ".local" / "bin"
DESKTOP_DIR = HOME / ".local" / "share" / "applications"
ICON_DIR = HOME / ".local" / "share" / "icons"

# ──────────────────────────────────────────────
# Repos (Fedora-specific)
# ──────────────────────────────────────────────
COPR_REPOS = [
    "tofik/nwg-shell",
    "alternateved/cliphist",
    "jdxcode/mise",
    "che/nerd-fonts",
    "g3tchoo/prismlauncher",
    "erikreider/SwayNotificationCenter",
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
        "git-delta",
        "git-lfs",
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
        "fzf",
        "bat",
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
        "wf-recorder",
        "swappy",
        "wl-clipboard",
        "geoclue2",
        "gammastep",
        "nwg-bar",
        "nwg-displays",
        "SwayNotificationCenter",
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
        "libpcap-devel",
        "libusb1-devel",
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
        "git-delta",
        "fzf",
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
        "wf-recorder",
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
        "git-delta",
        "fzf",
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
        "wf-recorder",
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
    name: str  # binary + desktop-file name, e.g. "signal-desktop"
    display_name: str  # shown in launchers, e.g. "Signal"
    url_template: str  # {version} placeholder optional
    version: str | None = None  # None = unversioned / self-updating URL
    gpg_key_url: str | None = None  # vendor signing key (.asc)
    gpg_sig_url_template: str | None = None  # detached signature URL
    icon_url: str | None = None  # icon downloaded from the internet
    categories: str = "Utility;"  # .desktop Categories
    wm_class: str | None = None  # StartupWMClass

    @property
    def url(self) -> str:
        return self.url_template.format(version=self.version)

    @property
    def gpg_sig_url(self) -> str | None:
        if self.gpg_sig_url_template is None:
            return None
        return self.gpg_sig_url_template.format(version=self.version)


APPS = [
    AppInstall(
        name="obsidian",
        display_name="Obsidian",
        version="1.10.6",
        url_template="https://github.com/obsidianmd/obsidian-releases/releases/download/v{version}/Obsidian-{version}.AppImage",
        icon_url="https://obsidian.md/images/obsidian-logo-gradient.svg",
        categories="Office;",
        wm_class="obsidian",
    ),
    AppInstall(
        name="headlamp",
        display_name="Headlamp",
        version="0.43.0",
        url_template="https://github.com/kubernetes-sigs/headlamp/releases/download/v{version}/Headlamp-{version}-linux-x64.AppImage",
        icon_url="https://raw.githubusercontent.com/kubernetes-sigs/headlamp/main/docs/images/icon.png",
        categories="Development;",
        wm_class="Headlamp",
    ),
    AppInstall(
        name="signal-desktop",
        display_name="Signal",
        url_template="https://updates.signal.org/desktop/signal-desktop.AppImage",
        gpg_key_url="https://updates.signal.org/static/desktop/appimage.asc",
        gpg_sig_url_template="https://updates.signal.org/desktop/signal-desktop.AppImage.gpg",
        icon_url="https://raw.githubusercontent.com/signalapp/Signal-Desktop/main/build/icons/png/1024x1024.png",
        categories="Network;InstantMessaging;",
        wm_class="signal",
    ),
]

# ──────────────────────────────────────────────
# oh-my-zsh
# ──────────────────────────────────────────────
ZSH_CUSTOM = Path(f"{HOME}/.oh-my-zsh/custom")
ZSH_PLUGINS = {
    "zsh-autosuggestions": "https://github.com/zsh-users/zsh-autosuggestions",
    "zsh-syntax-highlighting": "https://github.com/zsh-users/zsh-syntax-highlighting",
    "zsh-completions": "https://github.com/zsh-users/zsh-completions",
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
# vscode is no-folding: ~/.config/Code/User/ holds heavy runtime state
# (workspaceStorage, globalStorage, ...) that must stay outside the repo
STOW_NO_FOLDING = ["my-scripts", "pgcli", "vscode"]

# ──────────────────────────────────────────────
# Neovim
# ──────────────────────────────────────────────
LAZY_NVIM_REPO = "https://github.com/folke/lazy.nvim.git"
LAZY_NVIM_PATH = HOME / ".local" / "share" / "nvim" / "lazy" / "lazy.nvim"

# ──────────────────────────────────────────────
# VNotes
# ──────────────────────────────────────────────
VNOTES_DIR = HOME / "vnotes"
VNOTES_REPO = "git@github.com:zezav-cz/vnotes.git"

# ──────────────────────────────────────────────
# Claude Code — MCP servers
# ──────────────────────────────────────────────
CLAUDE_CONFIG = HOME / ".claude.json"
MCP_SERVERS = {
    "sequential-thinking": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
        "env": {},
    },
    "vnotes": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(VNOTES_DIR)],
        "env": {},
    },
    "kubernetes-mcp-server": {
        "command": "npx",
        "args": ["-y", "kubernetes-mcp-server@latest", "--read-only"],
    },
}
