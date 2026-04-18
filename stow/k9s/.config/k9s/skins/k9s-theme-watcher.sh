#!/bin/bash

CONFIG="$HOME/.config/k9s/config.yaml"

apply_theme() {
    local scheme="$1"
    echo "Apply: $scheme"

    if [[ "$scheme" == *"prefer-dark"* ]]; then
        sed -i 's/skin: gruvbox-light/skin: gruvbox-dark/' "$CONFIG"
        echo "Switched k9s to gruvbox-dark"
    else
        sed -i 's/skin: gruvbox-dark/skin: gruvbox-light/' "$CONFIG"
        echo "Switched k9s to gruvbox-light"
    fi
}

current=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
apply_theme "$current"

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    apply_theme "$line"
done
