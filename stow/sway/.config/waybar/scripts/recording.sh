#!/usr/bin/env bash
set -euo pipefail

# Waybar module: red REC indicator while wf-recorder is running.
if pgrep -x wf-recorder >/dev/null; then
  printf '{"text": "󰑊 REC", "class": "recording", "tooltip": "Screen recording in progress — click to stop"}\n'
else
  printf '{"text": ""}\n'
fi
