{
  lib,
  runCommand,
  makeWrapper,
  claude-desktop,
}:

# Builds a thin wrapper around the base claude-desktop package that pins it to
# its own Electron userData directory, so several fully independent instances
# (personal / work) can be installed and run side by side.
#
# Everything that makes an instance an instance lives in userData: the session
# cookies and safeStorage-encrypted tokens, Local Storage / IndexedDB,
# claude_desktop_config.json (MCP servers) and Logs. The app reads
# CLAUDE_USER_DATA_DIR and relocates all of it -- the config-dir resolver in
# resources/app.asar short-circuits on that variable too, so
# claude_desktop_config.json follows the same directory rather than staying in
# ~/.config/Claude.
#
# Electron's single-instance lock (SingletonLock/SingletonSocket) is created
# inside userData as well, which is what lets both wrappers have a running
# process at the same time instead of the second launch just focusing the
# first one's window.
#
# Two more per-instance knobs the wrapper sets:
#   CHROME_DESKTOP  Electron's Linux setAsDefaultProtocolClient() passes this
#                   desktop-file name to `xdg-settings set
#                   default-url-scheme-handler claude`. Only one instance can
#                   own claude:// at a time, so this makes it the one launched
#                   most recently -- which is the one an OAuth callback should
#                   land in.
#   --class         Chromium's WM_CLASS / Wayland app_id, so sway window rules
#                   and the taskbar can tell the two apart.
{
  profile, # short id: userData dir suffix, binary suffix, desktop-file suffix
  label, # name shown in launchers
  userDataDir, # absolute path; must not be shared with another profile
}:

let
  desktopName = "com.anthropic.Claude-${profile}";
  wmClass = "com.anthropic.Claude.${profile}";
in
runCommand "claude-desktop-${profile}-${claude-desktop.version}"
  {
    nativeBuildInputs = [ makeWrapper ];
    inherit (claude-desktop) meta;
    passthru = {
      inherit
        profile
        label
        userDataDir
        desktopName
        ;
      base = claude-desktop;
    };
  }
  ''
    mkdir -p $out/bin $out/share/applications

    makeWrapper ${claude-desktop}/bin/claude-desktop $out/bin/claude-desktop-${profile} \
      --set CLAUDE_USER_DATA_DIR ${lib.escapeShellArg userDataDir} \
      --set CHROME_DESKTOP ${desktopName}.desktop \
      --add-flags --class=${wmClass}

    # Per-profile icon name: both profiles land in the same home-manager
    # profile, so they must not both try to install share/icons/**/claude-desktop.png.
    for src in ${claude-desktop}/share/icons/hicolor/*/apps/claude-desktop.png; do
      size=$(basename "$(dirname "$(dirname "$src")")")
      install -Dm444 "$src" $out/share/icons/hicolor/$size/apps/claude-desktop-${profile}.png
    done

    substitute ${claude-desktop}/share/applications/com.anthropic.Claude.desktop \
      $out/share/applications/${desktopName}.desktop \
      --replace-fail "Name=Claude" ${lib.escapeShellArg "Name=${label}"} \
      --replace-fail "Icon=claude-desktop" "Icon=claude-desktop-${profile}" \
      --replace-fail "Chromium derives from" "the wrapper's --class flag sets," \
      --replace-fail "# package.json desktopName, so docks group windows under this entry." "# so docks group this profile's windows under this entry alone." \
      --replace-fail "StartupWMClass=com.anthropic.Claude" "StartupWMClass=${wmClass}" \
      --replace-fail "${claude-desktop}/bin/claude-desktop" "$out/bin/claude-desktop-${profile}"
  ''
