# zsh_plugins.sh - meant to be sourced in .zshrc

if [[ ($- == *i*) && -n "$ZSH_VERSION" ]]; then
    # -- oh-my-zsh
    [[ -z $STARSHIP_SHELL ]] && export ZSH_THEME="mytheme"
    DEFAULT_USER="basnijholt"
    export DISABLE_AUTO_UPDATE=true  # Speedup of 40%
    plugins=( git dirhistory history sudo iterm2 uv )
    command -v eza >/dev/null && zstyle ':omz:lib:directories' aliases no  # Skip aliases in directories.zsh if eza
    export ZSH=~/dotfiles/submodules/oh-my-zsh
    source $ZSH/oh-my-zsh.sh

    # -- zsh plugins
    source ~/dotfiles/submodules/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ~/dotfiles/submodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source ~/dotfiles/submodules/zsh-fzf-history-search/zsh-fzf-history-search.zsh

    # -- fix Atuin [Ctrl-r] key binding
    if command -v atuin &> /dev/null; then
        bindkey -M emacs '^r' atuin-search  # This again because `omz/lib/key-bindings.zsh` overwrote it
    fi

    # -- zsh-z - but only if zoxide is not installed
    if ! command -v zoxide &> /dev/null; then
        export ZSHZ_CD=cd
        source ~/dotfiles/submodules/zsh-z/zsh-z.plugin.zsh
    fi

    # -- autoenv - but only if direnv is not installed
    if ! command -v direnv &> /dev/null; then
        # needs to happen after .bash_profile (for conda) which
        # is why it is not loaded as a plugin
        export AUTOENV_ASSUME_YES=true
        export AUTOENV_ENABLE_LEAVE=true
        export AUTOENV_ENV_FILENAME=".envrc"
        export AUTOENV_ENV_LEAVE_FILENAME=".envrc.leave"
        source ~/.autoenv/activate.sh
    fi
fi
