# misc.sh - meant to be sourced in .bash_profile/.zshrc

# Homebrew (before dotbins because eza is not in dotbins on MacOS)
if [ -f "/opt/homebrew/bin/brew" ]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"
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
