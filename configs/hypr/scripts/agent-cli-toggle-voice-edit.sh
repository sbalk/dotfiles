#!/usr/bin/env bash

# Toggle script for agent-cli voice-edit with Hyprland
#
# This script provides a simple toggle mechanism for voice voice-edit:
# - First invocation: Starts voice-edit in the background
# - Second invocation: Stops voice-edit and displays the result
#
# Usage: Bind this script to a key in your Hyprland config:
# bind = $HOLD_HOME, R, exec, ~/.config/hypr/scripts/toggle-voice-edit.sh

# Check if agent-cli voice-edit is already running
if pgrep -f "agent-cli voice-edit" > /dev/null; then
    # Voice edit is running - stop it
    # SIGINT tells agent-cli to stop recording and process the audio
    pkill -INT -f "agent-cli voice-edit"
    notify-send -t 3000 "🛑 Voice edit Stopped" "Processing results..."
else
    # Voice edit is not running - start it

    # Ensure agent-cli is in PATH (adjust path as needed)
    export PATH="$PATH:/home/$(whoami)/.local/bin"

    # Notify user that recording has started
    notify-send -t 3000 "🎙️ Voice edit Started" "Listening in background..."

    # Start voice-edit in background:
    # - agent-cli voice-edit: Runs voice-edit
    # - 2>/dev/null: Suppresses error output
    # - OUTPUT=$(...): Captures the voice-edit result when process ends
    # - &&: Only show result notification if command succeeds
    # - &: Runs entire command chain in background
    OUTPUT=$(agent-cli voice-edit --quiet 2>/dev/null) && {
        # Sync clipboard to primary selection
        wl-paste | wl-copy -p
        notify-send -t 5000 "📄 Voice edit Result" "$OUTPUT"
    } &
fi
