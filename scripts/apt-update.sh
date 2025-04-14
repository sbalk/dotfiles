#!/usr/bin/env bash

# Simple Debian update script. Run with sudo: sudo ./update_basic.sh

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Debian System Update ---"

# 1. Update package lists
echo "[1/4] Updating package lists..."
apt update

# 2. Upgrade installed packages (assume 'yes' to prompts)
echo "[2/4] Upgrading installed packages..."
apt upgrade -y

# 3. Remove automatically installed packages that are no longer needed
echo "[3/4] Removing unused packages..."
apt autoremove -y

# 4. Clean up old downloaded package files
echo "[4/4] Cleaning up package cache..."
apt autoclean -y

echo "--- System Update Completed Successfully ---"

# Check if a reboot is needed (optional, but good practice)
if [ -f /var/run/reboot-required ]; then
    echo "---"
    echo "Warning: A reboot is required for some updates to take effect."
    echo "---"
fi

exit 0

