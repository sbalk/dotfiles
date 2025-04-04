#!/bin/bash

echo "~/dotfiles"
rsync-time-machine ~/dotfiles /Volumes/4TB/dotfiles

echo "~/Code"
rsync-time-machine ~/Code /Volumes/4TB/Code

echo "~/Sync"
rsync-time-machine ~/Sync /Volumes/4TB/Sync

echo "~/Lightroom"
rsync-time-machine ~/Lightroom /Volumes/4TB/Lightroom
