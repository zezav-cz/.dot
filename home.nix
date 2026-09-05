{
  pkgs,
  inputs,
  ccstatusline,
  jira-cli,
  claude-desktop,
  ...
}:

{
  home.username = "jantrojak";
  home.homeDirectory = "/home/jantrojak";

  # Bumping this after the initial setup is not required/recommended;
  # it pins the home-manager config format, not package versions.
  home.stateVersion = "24.11";

  home.sessionVariables = {
    GOPRIVATE = "github.com/zezav-cz/*";
  };

  # recommended for non-NixOS Linux (NIX_PATH, TERMINFO_DIRS, XDG data dirs)
  targets.genericLinux.enable = true;

  # 1:1 with stow/mise/.config/mise/config.toml. vn is our own private repo's
  # flake output (~/dev/zezav/vn#packages.default); ccstatusline and jira-cli
  # are custom derivations at nix/*.nix — ccstatusline's npm tarball is a
  # single bundled file with no runtime deps (no buildNpmPackage needed);
  # jira-cli has no nixpkgs package so it's a plain buildGoModule.
  home.packages = with pkgs; [
    inputs.vn.packages.${pkgs.system}.default
    ccstatusline
    jira-cli
    asciidoctorj
    cilium-cli
    hubble # cilium-hubble
    fd
    fluxcd # flux2
    rake # gem:rake
    gh
    glab
    s5cmd
    kubernetes-helm # helm
    k9s
    krew
    kubectl
    kubectx # also provides kubens
    minio-client # mc
    neovim
    nodejs # node
    pandoc
    pgcli
    python312 # python
    go-task # task
    usage
    yq-go # yq
    go_1_25 # go
    lazygit
    awscli2 # aws
    fx
    aws-cdk-cli # npm:aws-cdk
    google-cloud-sdk # gcloud
    terraform-docs
    pipx
    uv
    git-fame
    yarn
    kind
    yazi
    backblaze-b2 # pipx:b2
    argo-workflows # argo
    zoxide
    dive
    bettercap

    # GUI apps — migrated off ansible/roles/apps (AppImage/tarball + hand
    # rolled .desktop entries, see ansible/roles/apps/vars/main.yml and
    # tasks/main.yml, now commented out there). .desktop files ship inside
    # these packages' own share/applications/ and land in
    # ~/.nix-profile/share/applications automatically; XDG_DATA_DIRS in the
    # systemd --user session already includes that path, so launchers pick
    # them up with no extra wiring.
    telegram-desktop
    slack
    obsidian
    headlamp
    signal-desktop
    vscode
    claude-desktop
  ];

  programs.home-manager.enable = true;
}
