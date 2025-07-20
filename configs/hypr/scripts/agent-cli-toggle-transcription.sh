#!/usr/bin/env bash

# Toggle script for agent-cli transcription with Hyprland
#
# This script provides a simple toggle mechanism for voice transcription:
# - First invocation: Starts transcription in the background
# - Second invocation: Stops transcription and displays the result
#
# Usage: Bind this script to a key in your Hyprland config:
# bind = $HOLD_HOME, R, exec, ~/.config/hypr/scripts/toggle-transcription.sh

# Check if agent-cli transcribe is already running
if pgrep -f "agent-cli transcribe" > /dev/null; then
    # Transcription is running - stop it
    # SIGINT tells agent-cli to stop recording and process the audio
    pkill -INT -f "agent-cli transcribe"
    notify-send -t 3000 "🛑 Transcription Stopped" "Processing results..."
else
    # Transcription is not running - start it

    # Ensure agent-cli is in PATH (adjust path as needed)
    export PATH="$PATH:/home/$(whoami)/.local/bin"

    # Notify user that recording has started
    notify-send -t 3000 "🎙️ Transcription Started" "Listening in background..."

    # Start transcription in background:
    # - agent-cli transcribe --llm: Runs transcription with LLM processing
    # - 2>/dev/null: Suppresses error output
    # - OUTPUT=$(...): Captures the transcription result when process ends
    # - &&: Only show result notification if command succeeds
    # - &: Runs entire command chain in background
    OUTPUT=$(agent-cli transcribe --llm --quiet 2>/dev/null) && \
    notify-send -t 5000 "📄 Transcription Result" "$OUTPUT" &
fi
