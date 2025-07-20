#!/usr/bin/env bash

# Toggle script for agent-cli autocorrect with Hyprland

export PATH="$PATH:/home/$(whoami)/.local/bin"
notify-send "Autocorrect triggered 🤯"
OUTPUT=$(agent-cli autocorrect --quiet 2>/dev/null) && \
    notify-send "Corrected result" "$OUTPUT" &