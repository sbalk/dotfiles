from tree import print_with_comments, list_files

# Directory and file descriptions
descriptions = {
    "configs": "Configuration files for various tools",
    "Dockerfile": "Docker container that runs this dotfiles configuration",
    "README.md": "You are here",
    "atuin": "Shell history management",
    "bash": "Bash-specific configuration",
    "conda": "Conda/Mamba configuration",
    "dask": "Dask distributed computing",
    "direnv": "Directory-specific environment setup",
    "git": "Git configuration",
    "iterm": "iTerm2 profiles",
    "karabiner": "Keyboard customization for macOS",
    "keyboard-maestro": "Keyboard Maestro macros and configurations",
    "mamba": "Mamba package manager settings",
    "nix-darwin": "Nix configuration for macOS",
    "shell": "Shell-agnostic configurations",
    "starship": "Cross-shell prompt",
    "syncthing": "File synchronization",
    "zsh": "Zsh-specific configuration",
    "submodules": "Git submodules for external tools",
    "autoenv": "Directory-based environments",
    "dotbot": "Dotfiles installation",
    "dotbins": "Binaries manager in dotfiles",
    "mydotbins": "CLI tool binaries managed by dotbins",
    "oh-my-zsh": "Zsh framework",
    "tmux": "oh-my-tmux configuration",
    "rsync-time-backup": "Time-Machine style backup with rsync",
    "zsh-autosuggestions": "Zsh autosuggestions plugin",
    "zsh-syntax-highlighting": "Zsh syntax highlighting",
    "zsh-fzf-history-search": "Fuzzy history search",
    "install.conf.yaml": "Dotbot configuration",
    "install": "Installation script",
    "uninstall.py": "Uninstallation script",
}


if __name__ == "__main__":
    tree = list_files(folder=".", excludes=["^secrets$", "^scripts/.+$", r"^\..+$"])
    print("```bash")
    print_with_comments(tree, descriptions)
    print("```")
