#!/bin/zsh

# add as cronjob, using `crontab -e`:
# 0 */1 * * * $HOME/dotfiles/scripts/rclone.sh >> $HOME/dotfiles/scripts/rclone_log.txt


# Check if the script is already running
# https://stackoverflow.com/a/45429634/3447047
if ps ax | grep $0 | grep -v $$ | grep bash | grep -v grep
then
    echo "The script is already running."
    exit 1
fi

. ~/.bash_profile

echo `date`

FLAGS="--stats-one-line --progress --fast-list --log-file=rclone-log.txt"

# Do the syncing
echo "sync ~/Lightroom"
rclone sync ~/Lightroom secret-lightroom-b2: "${=FLAGS}"

echo "sync ~/Sync"
rclone sync ~/Sync secret-sync-b2: --copy-links "${=FLAGS}"

echo "sync ~/Code"
rclone sync ~/Code secret-code-b2: --copy-links "${=FLAGS}"

if [[ -d /Volumes/4TB ]]; then
  echo "sync /Volumes/4TB/Photos"
  rclone sync /Volumes/4TB/Photos secret-photos-b2: "${=FLAGS}"

  echo "sync /Volumes/4TB/Websites"
  rclone sync /Volumes/4TB/Websites secret-websites-b2: "${=FLAGS}"
fi
