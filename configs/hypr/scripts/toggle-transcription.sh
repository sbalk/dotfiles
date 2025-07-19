#!/bin/bash

if pgrep -f "agent-cli transcribe" > /dev/null; then
    pkill -INT -f "agent-cli transcribe"
    notify-send "Transcription Stopped" "The transcription process has been terminated."
else
    notify-send "Transcription Started" "Starting transcription process..."
    agent-cli transcribe --llm
fi
