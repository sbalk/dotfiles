# prefer_zsh.sh - meant to be sourced in .bash_profile/.bashrc

# Change to zsh only if it's interactive, from https://unix.stackexchange.com/a/26782
if [[ ($- == *i*) && -z "$ZSH_VERSION" && "$(hostname)" != "DietPi" ]]; then
    export SHELL=`which zsh`
    if [[ ! -z "${SHELL// }" ]]; then
        # Only if zsh is installed and we're not already in zsh
        exec "$SHELL" -l
    fi
fi
