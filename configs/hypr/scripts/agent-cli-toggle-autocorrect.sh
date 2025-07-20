#!/usr/bin/env bash

# Toggle script for agent-cli autocorrect with Hyprland

export PATH="$PATH:/home/$(whoami)/.local/bin"
notify-send "🪄 Autocorrect triggered"
OUTPUT=$(agent-cli autocorrect --quiet 2>/dev/null) && {
    # Sync clipboard to primary selection
    wl-paste | wl-copy -p
    notify-send -t 5000 "✅ Corrected result" "$OUTPUT"
} &
