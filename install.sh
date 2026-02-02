#!/usr/bin/env bash

# Exit if any command fails
set -e

echo "🚀 Starting your Omarchy setup..."

# 1. FIX: Correct Yay Installation
if ! command -v yay &> /dev/null; then
    echo "🛠️ Installing yay (AUR helper)..."
    sudo pacman -S --needed base-devel git
    # Corrected URL
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# 2. Package Installation
echo "📦 Installing packages from your list..."
if [ -f pkglist.txt ]; then
    grep -v '^#' pkglist.txt | xargs yay -S --needed --noconfirm
else
    echo "❌ Error: pkglist.txt not found!"
    exit 1
fi

# 3. FIX: Safe Stow Logic
echo "🔗 Symlinking dotfiles..."
folders=(hypr mako waybar yazi zsh nvim kitty)

for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
        echo "Stowing $folder..."
        # --adopt handles conflicts by 'adopting' existing files into your repo
        stow --adopt "$folder"
    else
        echo "⚠️ Folder '$folder' not found in repo, skipping."
    fi
done

# 4. VM-Specific Setup
if systemd-detect-virt -q; then
    echo "🖥️ VM Detected: Enabling Guest Services..."
    sudo systemctl enable --now vboxservice.service
fi

echo "✅ All done! Please reboot to apply changes."
