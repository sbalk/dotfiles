#!/bin/bash

# Poor man's Supervisord/Launchd/Systemd for eqMac because it keeps crashing

# Add to `crontab -e`:
# */1 * * * * $HOME/dotfiles/eqMac.sh

APP="/Applications/eqMac.app"
ps -e | grep $APP | grep -v grep &> /dev/null
if [ "$?" -eq 1 ]; then
    open -a $APP
fi

SPEAKERS=$(system_profiler SPAudioDataType)

ioreg -r -k AppleClamshellState -d 4 \
    | grep AppleClamshellState  \
    | head -1 \
    | grep Yes &> /dev/null
if [ "$?" -eq 0 ]; then
    # Is in clamshell mode
    echo "TODO"
fi