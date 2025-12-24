#!/bin/bash

GS_BIN="gammastep"

toggle() {
    if pgrep -x "$GS_BIN" > /dev/null; then
        pkill -x "$GS_BIN"
    else
        $GS_BIN &
    fi
}

if [ "$1" == "toggle" ]; then
    toggle
    exit 0
fi

if pgrep -x "$GS_BIN" > /dev/null; then
    TEXT="On"
    CLASS="on"
    TOOLTIP="Gammstep: on"
else
    TEXT="Off"
    CLASS="off"
    TOOLTIP="Gammstep: off"
fi

printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
