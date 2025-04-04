from tree import print_with_comments, list_files

# Directory and file descriptions
descriptions = {
    "main.sh": "Main shell configuration file",
    "00_prefer_zsh.sh": "ZSH auto-switching",
    "05_zsh_completions.sh": "ZSH completions setup",
    "10_aliases.sh": "Shell aliases",
    "20_exports.sh": "Environment variables",
    "30_misc.sh": "Miscellaneous settings",
    "40_keychain.sh": "SSH key management",
    "50_python.sh": "Python environment setup",
    "60_slurm.sh": "HPC cluster integration",
    "70_zsh_plugins.sh": "ZSH plugins setup",
}

if __name__ == "__main__":
    tree = list_files(folder="configs/shell", level=3)
    print("```bash")
    print_with_comments(tree, descriptions)
    print("```")
