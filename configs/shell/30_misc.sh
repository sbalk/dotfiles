# misc.sh - meant to be sourced in .bash_profile/.zshrc

# Homebrew (before dotbins because eza is not in dotbins on MacOS)
if [ -f "/opt/homebrew/bin/brew" ]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"
fi


# atuin daemon management based on config
is_home_on_zfs() {
    mount | grep "$(df ~/ | tail -1 | awk '{print $1}')" | grep -q "zfs"
    return $?
}
if is_home_on_zfs; then
  export ATUIN_CONFIG_DIR="$HOME/.config/atuin/zfs"
  if ! pgrep -f "atuin daemon" >/dev/null; then
    echo "Starting Atuin daemon based on config"
    nohup atuin daemon >/dev/null 2>&1 &
  fi
fi

# Dotbins
[ -n "$ZSH_VERSION" ] && source "$HOME/.dotbins/shell/zsh.sh"
[ -n "$BASH_VERSION" ] && source "$HOME/.dotbins/shell/bash.sh"

# Rust
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Non-public parts
if [ -f "$HOME/dotfiles/secrets/main.sh" ]; then
    . "$HOME/dotfiles/secrets/main.sh"
fi
