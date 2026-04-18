#!/bin/bash

set() {
    gsettings set org.gnome.desktop.interface color-scheme "$1"
}

toggle() {
    current=$(gsettings get org.gnome.desktop.interface color-scheme)
    if [ "$current" = "'prefer-dark'" ]; then
        set "prefer-light"
    else
        set "prefer-dark"
    fi
}

if [ "$1" = "toggle" ]; then
    toggle
    exit 0
fi

current=$(gsettings get org.gnome.desktop.interface color-scheme)
if [ "$current" = "'prefer-dark'" ]; then
    printf '{"text": "󰖐", "class": "dark", "tooltip": "Theme: Dark"}\n'
else
    printf '{"text": "󰖙", "class": "light", "tooltip": "Theme: Light"}\n'
fi
