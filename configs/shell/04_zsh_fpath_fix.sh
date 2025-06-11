# 04_zsh_fpath_fix.sh - Reliably set Zsh fpath if it is missing system directories.
#
# This script is a safeguard for systems (especially older ones) with a minimal
# /etc/zshrc that doesn't initialize the function path ($fpath) correctly.
# It checks for a key system directory and, if it's missing from fpath,
# prepends the standard system paths.

if [[ -n "$ZSH_VERSION" ]]; then
  # The test: check if /usr/share/zsh/site-functions is in the fpath.
  # If not, we assume the fpath has been improperly configured and needs fixing.
  # The '[[ -d ... ]]' part ensures we only act if the directory actually exists.
  if [[ ${fpath[(Ie)/usr/share/zsh/site-functions]} -gt ${#fpath} && -d /usr/share/zsh/site-functions ]]; then

    # We construct the list of paths to add. We check for their existence first.
    # The order matters: local > site > version-specific.
    local -a system_paths=()
    [[ -d /usr/local/share/zsh/site-functions ]] && system_paths+=/usr/local/share/zsh/site-functions
    [[ -d /usr/share/zsh/site-functions ]] && system_paths+=/usr/share/zsh/site-functions
    [[ -d /usr/share/zsh/$ZSH_VERSION/functions ]] && system_paths+=/usr/share/zsh/$ZSH_VERSION/functions

    # Prepend the system paths to whatever is currently in fpath.
    # This ensures system functions can be found, while respecting anything
    # that may have already been added by other tools.
    fpath=("${system_paths[@]}" $fpath)

    unset system_paths
  fi
fi
