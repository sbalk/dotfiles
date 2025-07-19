#!/usr/bin/env bash

# This script sets a random wallpaper from ~/wallpapers

# Directory containing the wallpapers
WALLPAPER_DIR="$HOME/wallpapers"

# Check if the directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Wallpaper directory not found: $WALLPAPER_DIR"
  exit 1
fi

# Get a random wallpaper from the directory
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Set the wallpaper using swww
if [ -f "$RANDOM_WALLPAPER" ]; then
  swww img "$RANDOM_WALLPAPER" --transition-type any
else
  echo "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi
