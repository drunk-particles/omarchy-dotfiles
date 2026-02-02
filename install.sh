#!/usr/bin/env bash

# Exit if any command fails
set -e

echo "🚀 Starting your Omarchy setup..."

# 1. Install 'yay' first if it's missing (required for the AUR packages in your list)
if ! command -v yay &> /dev/null; then
    echo "🛠️ Installing yay (AUR helper)..."
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# 2. Filter out comments and install everything using yay
# This reads your list, ignores lines starting with #, and installs the rest
echo "📦 Installing packages from your list..."
grep -v '^#' pkglist.txt | xargs yay -S --needed --noconfirm

# 3. Use Stow to link your configs
# This assumes your folders are named 'hypr', 'kitty', etc.
echo "🔗 Symlinking dotfiles..."
folders=(hypr mako waybar yazi zsh nvim kitty)

for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
        echo "Stowing $folder..."
        stow "$folder"
    else
        echo "⚠️ Folder '$folder' not found in repo, skipping."
    fi
done

echo "✅ All done! Log out and back in to see changes."
