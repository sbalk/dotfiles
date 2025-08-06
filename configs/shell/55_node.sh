# node.sh - meant to be sourced in .bash_profile/.zshrc

# Function to get the current shell name
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
else
    echo "Unsupported shell"
fi

# -- NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# zstyle ':omz:plugins:nvm' lazy yes

# -- Helper functions
create_node_version() {
    local version=${1:-"lts/*"}
    nvm install "$version"
    nvm use "$version"
    echo "$version" > .nvmrc
}

create_direnv_node() {
    echo "nvm use --lts" > .envrc
    direnv allow .
}

# Add pnpm to PATH if installed
PNPM_HOME="$HOME/Library/pnpm"
if [ -d "$PNPM_HOME" ]; then
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

# Add Yarn to PATH if installed
if [ -d "$HOME/.yarn/bin" ]; then
    export PATH="$HOME/.yarn/bin:$PATH"
fi

# Add bun to PATH if installed
if [ -d "$HOME/.bun/bin" ]; then
    export PATH="$HOME/.bun/bin:$PATH"
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi