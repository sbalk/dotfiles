# aliases.sh - meant to be sourced in .bash_profile/.zshrc

if [[ $- == *i* ]]; then
    alias mmc="mm create -n"
    alias mmd="mm deactivate"
    alias mma="mm activate"
    alias mmi="mm install -c conda-forge"
    alias mml="mm env list"
    alias mmremove="mm remove env -n"
    alias ca="conda activate"
    alias cl="conda info --envs"
    alias ci="conda install -c conda-forge"
    alias cr="code -r ."
    alias countfiles='f(){ ls -1 "$1" | wc -l; }; f'
    alias mm="micromamba"
    alias p="pytest"
    alias py="python"
    alias pc="pre-commit run --all-files"
    alias ccat='command cat'
    alias last_conda_repodata_update='curl -sI https://conda.anaconda.org/conda-forge/linux-64/repodata.json | grep "last-modified"'  # Also see https://anaconda.statuspage.io/ and https://github.com/conda/infrastructure/issues/892
    alias gs='git status'  # I use `gst` from `oh-my-zsh` git plugin but this is a frequent typo
    alias fixssh='eval $(tmux show-env -s |grep "^SSH_")'  # https://stackoverflow.com/a/34683596
    alias gcai="${HOME}/dotfiles/scripts/commit.py --edit "
    alias gcaia="${HOME}/dotfiles/scripts/commit.py --edit --all "
    alias c='code'
    alias ze='zellij attach --create'

    if [[ `uname` == 'Darwin' ]]; then
        alias j='jupyter notebook'
        alias ci='code-insiders'
        alias s='/usr/local/bin/subl'
        alias ss='open -b com.apple.ScreenSaver.Engine'
        alias tun='autossh -N -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -L 8888:localhost:9999 cw'
        alias nixswitch="darwin-rebuild switch --flake ~/dotfiles/configs/nix-darwin"

        # Relies on having installed x86 brew like:
        # arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        alias x86brew="arch -x86_64 /usr/local/bin/brew"
        alias brew="/opt/homebrew/bin/brew"  # M1 version, to avoid from using x86 version accidentally
    fi
    if [[ `uname` == 'Linux' ]]; then
        alias pbcopy='wl-copy'  # Just because of muscle memory...
    fi
fi
