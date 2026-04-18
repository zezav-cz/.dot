#!/usr/bin/env bash
set -euo pipefail

apply_theme() {
    local scheme="$1"

    if [[ "$scheme" == *"prefer-dark"* ]]; then
        killall -USR1 foot 2>/dev/null
        echo "Switched to Dark Mode (SIGUSR1)"
    else
        killall -USR2 foot 2>/dev/null
        echo "Switched to Light Mode (SIGUSR2)"
    fi
}

current=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
apply_theme "$current"

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    apply_theme "$line"
done
