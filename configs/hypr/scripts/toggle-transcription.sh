#!/usr/bin/env bash

# Simple toggle for transcription in background

if pgrep -f "agent-cli transcribe" > /dev/null; then
    # Stop transcription
    pkill -INT -f "agent-cli transcribe"
    notify-send "Transcription Stopped" "The transcription process has been terminated."
else
    # Start transcription in background
    agent-cli transcribe --llm > /dev/null 2>&1 &
    notify-send "Transcription Started" "Listening in background..."
fi