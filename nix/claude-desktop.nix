{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libGL,
  libappindicator,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  libxcb,
  libxkbcommon,
  libgbm,
  nspr,
  nss,
  pango,
  systemd,
  wayland,
  xdg-utils,
  libxtst,
  libxscrnsaver,
  libxrender,
  libxrandr,
  libxi,
  libxfixes,
  libxext,
  libxdamage,
  libxcursor,
  libxcomposite,
  libx11,
  libxshmfence,
  libxkbfile,
}:

# Repackaged from Anthropic's own apt repo (same one `apt-cache policy
# claude-desktop` points at: downloads.claude.ai/claude-desktop/apt/stable) —
# not a nixpkgs package. Follows the same pattern as nixpkgs' own `slack`
# derivation (patchelf the vendored Electron binary + wrap), since this is
# the same kind of .deb-distributed Electron app.
#
# chrome-sandbox ships in the .deb but Nix strips its setuid bit like any
# other build output, so Electron falls back to the unprivileged-userns
# sandbox — the same fallback path ansible/roles/apps already relies on for
# Obsidian/Signal AppImages (see the apparmor_restrict_unprivileged_userns
# sysctl there). If that kernel knob isn't set, launch will fail; re-add
# `--no-sandbox` to the wrapper below in that case.
stdenv.mkDerivation rec {
  pname = "claude-desktop";
  version = "1.46388.2";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-mL9U6F5JFgaMQoFFmw8EMdj/aANHc/PumDEdcgZWarE=";
  };

  rpath =
    lib.makeLibraryPath [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libGL
      libappindicator
      libdrm
      libnotify
      libsecret
      libuuid
      libxcb
      libxkbcommon
      libgbm
      nspr
      nss
      pango
      stdenv.cc.cc
      systemd
      wayland
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxkbfile
      libxshmfence
    ]
    + ":${lib.getLib stdenv.cc.cc}/lib64";

  buildInputs = [
    gtk3 # needed for GSETTINGS_SCHEMAS_PATH
  ];

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  dontUnpack = true;
  dontBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    # chrome-sandbox is setuid in the .deb; dpkg -x mishandles that, so
    # extract the raw filesystem tarball instead (same as nixpkgs' slack).
    dpkg --fsys-tarfile $src | tar --extract
    rm -rf usr/share/lintian usr/share/doc

    mkdir -p $out
    mv usr/* $out
    chmod -R g-w $out

    for file in $(find $out -type f \( -perm /0111 -o -name \*.so\* \) ); do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
      patchelf --set-rpath ${rpath}:$out/lib/claude-desktop "$file" || true
    done

    rm $out/bin/claude-desktop
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}

    # Exec= is a bare command name in the upstream .desktop (relies on
    # $PATH), which breaks when the launcher's own process doesn't have
    # ~/.nix-profile/bin on PATH (e.g. sway started via a display manager,
    # not a login shell that sources .zprofile). Pin it to the store path,
    # same fixup nixpkgs itself does for its own packaged .desktop entries.
    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
