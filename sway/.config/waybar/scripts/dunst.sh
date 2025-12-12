#!/bin/bash

# Handle the "toggle" argument
if [ "$1" = "toggle" ]; then
    if [ "$(dunstctl is-paused)" == "false" ]; then
        notify-send -u normal -t 2000 "Dunst" "Notifications Paused"
        sleep 0.5 
        dunstctl set-paused true
    else
        dunstctl set-paused false
        notify-send -u normal -t 2000 "Dunst" "Notifications Resumed"
    fi
    pkill -SIGRTMIN+10 waybar
    exit
fi

# --- STATUS CHECK ---
STATUS=$(dunstctl is-paused)

if [ "$STATUS" == "false" ]; then
    TEXT="On"
    CLASS="active"
    TOOLTIP="Notifications: Active"
else
    TEXT="Off"
    CLASS="muted"
    TOOLTIP="Do Not Disturb: Enabled"
fi

printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
