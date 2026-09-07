{
  config,
  pkgs,
  inputs,
  ccstatusline,
  jira-cli,
  claude-desktop,
  ...
}:

let
  # Two fully separate Claude Desktop instances (own cookies/login, own
  # claude_desktop_config.json, own logs, own single-instance lock) built from
  # the one base package -- see nix/claude-desktop-profile.nix. The base
  # package is deliberately not in home.packages: installing it too would add a
  # third, unlabelled entry still pointing at ~/.config/Claude.
  mkClaudeDesktop = import ./nix/claude-desktop-profile.nix {
    inherit (pkgs) lib runCommand makeWrapper;
    inherit claude-desktop;
  };

  claude-desktop-personal = mkClaudeDesktop {
    profile = "personal";
    label = "Claude (Personal)";
    userDataDir = "${config.home.homeDirectory}/.config/Claude-personal";
  };

  claude-desktop-work = mkClaudeDesktop {
    profile = "work";
    label = "Claude (Work)";
    userDataDir = "${config.home.homeDirectory}/.config/Claude-work";
  };

  # VS Code: nixpkgs unpacks the upstream asar and replaces node_modules.asar
  # with a symlink to the extracted node_modules (see the package's postPatch),
  # but leaves no node_modules.asar.unpacked. Electron resolves reads under
  # <archive>.asar/ through <archive>.asar.unpacked/, so onig.wasm
  # (vscode-oniguruma) can no longer be fetched:
  #   Failed to fetch: TypeError: Failed to fetch
  #     at FK._loadVSCodeOnigurumaWASM
  # Oniguruma is the regex engine behind ALL TextMate tokenization -- without it
  # every language loses comment/string/keyword colours and only LSP semantic
  # tokens stay coloured, which looks like a half-broken theme rather than an
  # error. Pointing .unpacked at the same extracted tree restores it.
  #
  # Verified by launching each build with an isolated --user-data-dir and
  # grepping its renderer.log for _loadVSCodeOnigurumaWASM:
  #   nix 1.135.0 stock ....... fails      system 1.136.1 ......... OK
  #   nix 1.133.0 rebuilt ..... fails      nix 1.135.0 + this ..... OK
  # Note 1.133.0 rebuilt from current nixpkgs fails too -- this is a packaging
  # regression, not a VS Code version issue, so pinning the version does NOT
  # help. Drop this once nixpkgs ships node_modules.asar.unpacked again.
  vscode-fixed = pkgs.vscode.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      app="$out/lib/vscode/resources/app"
      ln -rs "$app/node_modules" "$app/node_modules.asar.unpacked"
    '';
  });
in
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
    bazel_9 # bazel — pin the major; plain `bazel` still resolves to 7.x

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
    vscode-fixed
    claude-desktop-personal
    claude-desktop-work
  ];

  programs.home-manager.enable = true;
}
