#!/usr/bin/env bash

# Check if install mode is enabled
INSTALL_MODE=$1

echo "📶 Connected to $(hostname)"
cd dotfiles || { echo "❌ Error: dotfiles directory not found"; exit 1; }
echo "📡 Pulling latest changes..."
git pull --autostash
echo "📦 Updating submodules..."
git submodule update --recursive --init --force
echo "🔄 Pruning lfs files..."
cd submodules/mydotbins
git lfs prune
cd ../..

# Only run install if INSTALL_MODE is true
if [[ "$INSTALL_MODE" == "install" ]]; then
  echo "🔄 Running install script..."
  ./install
else
  echo "⏭️ Skipping install (use 'install' parameter to run it)"
fi

echo "✅ Done!"
