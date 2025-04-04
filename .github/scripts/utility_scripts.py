from tree import print_with_comments, list_files

# Directory and file descriptions
descriptions = {
    "eqMac.sh": "Poor man's Supervisord/Launchd/Systemd for eqMac because it keeps crashing",
    "nbviewer.sh": "Script to share Jupyter notebooks via nbviewer",
    "pypi-sha256.sh": "Generate the commands to update a conda-forge feedstock",
    "rclone.sh": "Scheduled backups to B2 cloud storage",
    "rsync-time-machine.sh": "Create incremental Time Machine-like backups using rsync",
    "sync-dotfiles.sh": "Sync dotfiles to remote machines",
    "sync-local-dotfiles.sh": "Update dotfiles on the local machine",
    "sync-photos-to-truenas.sh": "Sync photos to TrueNAS server",
    "upload-file.sh": "Share files via various file hosting services",
}

if __name__ == "__main__":
    tree = list_files(folder="scripts", level=2)
    print("```bash")
    print_with_comments(tree, descriptions)
    print("```")
