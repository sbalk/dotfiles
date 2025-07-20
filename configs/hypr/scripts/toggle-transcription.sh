#!/usr/bin/env bash

if pgrep -f "agent-cli transcribe" > /dev/null; then
    # Stop transcription
    pkill -INT -f "agent-cli transcribe"
    notify-send "Transcription Stopped" "Processing results..."
else
    # Start transcription and capture output
    export PATH="$PATH:/home/$(whoami)/.local/bin"
    notify-send "Transcription Started" "Listening in background..."
    
    # Run in background, capture output, and show notification when done
    OUTPUT=$(agent-cli transcribe --llm --quiet 2>/dev/null) && \
    notify-send "Transcription Result" "$OUTPUT" &
fi
