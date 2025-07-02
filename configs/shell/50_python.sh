# python.sh - meant to be sourced in .bash_profile/.zshrc

# Function to get the current shell name
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
else
    echo "Unsupported shell"
fi

# -- Conda/Mamba/Micromamba
if command -v micromamba &> /dev/null; then
    # echo "Found micromamba"
    export MAMBA_EXE="$(command -v micromamba)"
    export MAMBA_ROOT_PREFIX="$HOME/micromamba"
    eval "$($MAMBA_EXE shell hook --shell "$SHELL_TYPE" $MAMBA_ROOT_PREFIX)"
elif [ -f "$HOME/mambaforge/etc/profile.d/conda.sh" ]; then
    # echo "Found mambaforge"
    eval "$($HOME/mambaforge/bin/conda shell.bash hook)"
    . "$HOME/mambaforge/etc/profile.d/mamba.sh"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    # echo "Found miniconda"
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
else
    [[ $- == *i* ]] && echo "No micromamba/mamba/conda found"
fi

# -- Add pixi to PATH if installed
if [ -f "$HOME/.pixi/bin/pixi" ]; then
    export PATH=$PATH:$HOME/.pixi/bin
    eval "$(pixi completion --shell "$SHELL_TYPE")"
fi

# -- Helper functions
create_direnv_micromamba() {
    local env_name=${1:-$(basename "$PWD")}
    echo "layout micromamba $env_name" > .envrc
    direnv allow .
}

create_direnv_venv() {
    echo "source .venv/bin/activate" > .envrc
    direnv allow .
}

create_direnv_pixi() {
    echo 'watch_file pixi.lock && eval "$(pixi shell-hook)"' > .envrc
    direnv allow .
}

create_and_activate_x86_conda_env() {
    ENV_NAME="$1"
    CONDA_SUBDIR=osx-64 micromamba create -n $ENV_NAME python
    micromamba activate $ENV_NAME
}

create_direnv_nix() {
    echo "use nix" > .envrc
    direnv allow .
}

# -- Fix Conda messing up prompt
if [[ $SHELL == *zsh ]]; then
    # https://github.com/conda/conda/issues/7031#issuecomment-560587364
    HOSTNAME="$(hostname)"  # Conda clobbers HOST, so we save the real hostname into another variable.
    precmd() {
        OLDHOST="${HOST}"
        HOST="${HOSTNAME}"
    }

    preexec() {
        HOST="${OLDHOST}"
    }
fi
