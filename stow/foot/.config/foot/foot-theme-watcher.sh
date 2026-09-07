#!/usr/bin/env bash
set -euo pipefail

# Keeps already-running foot windows AND newly-started ones in sync with the
# system light/dark preference: signals running instances, and writes the
# matching initial-color-theme into theme-mode.ini (included by foot.ini) so
# a fresh `foot` picks up the right theme immediately instead of always
# defaulting to dark.
THEME_MODE_INI="$HOME/.config/foot/theme-mode.ini"

write_theme_mode() {
    local theme_num="$1"

    # theme-mode.ini ships in the dotfiles repo as a seed default; the first
    # write here replaces the symlink with a real local file so subsequent
    # writes never touch the tracked repo copy.
    if [[ -L "$THEME_MODE_INI" ]]; then
        rm -f "$THEME_MODE_INI"
    fi
    printf '[main]\ninitial-color-theme=%s\n' "$theme_num" >"$THEME_MODE_INI"
}

apply_theme() {
    local scheme="$1"

    if [[ "$scheme" == *"prefer-dark"* ]]; then
        write_theme_mode 1
        killall -USR1 foot 2>/dev/null || true
        echo "Switched to Dark Mode (SIGUSR1)"
    else
        write_theme_mode 2
        killall -USR2 foot 2>/dev/null || true
        echo "Switched to Light Mode (SIGUSR2)"
    fi
}

current=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
apply_theme "$current"

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    apply_theme "$line"
done
