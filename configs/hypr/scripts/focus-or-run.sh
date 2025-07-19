#!/usr/bin/env bash

set -x  # Keep this for debugging if you want

APP_CLASS="$1"
APP_CMD="$2"

echo "Looking for class: $APP_CLASS"

# Get window address directly - this is the fixed approach
WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg a "$APP_CLASS" '.[] | select(.class | test($a; "i")) | .address' | head -n1)

if [ -n "$WINDOW_ADDRESS" ]; then
    echo "Found window with address: $WINDOW_ADDRESS"
    hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
    echo "Window not found, launching: $APP_CMD"
    $APP_CMD &
fi
