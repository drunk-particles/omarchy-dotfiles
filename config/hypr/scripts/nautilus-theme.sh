#!/bin/bash

CURRENT_THEME=$(readlink -f ~/.config/omarchy/current | xargs basename | tr '[:upper:]' '[:lower:]')  # Case-insensitive

if [[ "$CURRENT_THEME" == *"light"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

# Optional: Refresh open Nautilus windows
nautilus -q 2>/dev/null || true