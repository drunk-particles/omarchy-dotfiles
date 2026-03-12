#!/bin/bash

# Config paths for Omarchy
WAYBAR_DIR="$HOME/.config/waybar"
STYLE_DIR="$WAYBAR_DIR/css"
STATE_FILE="/tmp/waybar_style_state"

# 1. Detect all styles in your css subfolder
STYLES=($(ls "$STYLE_DIR"/*.css 2>/dev/null | xargs -n 1 basename))

if [ ${#STYLES[@]} -eq 0 ]; then
    notify-send -a "System" "Waybar Error" "No CSS files found in $STYLE_DIR" -u critical
    exit 1
fi

# 2. Get current state and cycle to the next style
CUR_INDEX=$(cat "$STATE_FILE" 2>/dev/null)
[[ "$CUR_INDEX" =~ ^[0-9]+$ ]] || CUR_INDEX=0
NEXT_INDEX=$(( (CUR_INDEX + 1) % ${#STYLES[@]} ))
SELECTED_STYLE="${STYLES[$NEXT_INDEX]}"

# 3. Apply the new style via symlink
ln -sf "$STYLE_DIR/$SELECTED_STYLE" "$WAYBAR_DIR/style.css"
echo "$NEXT_INDEX" > "$STATE_FILE"

# 4. Restart Waybar (The Omarchy way)
omarchy-restart-waybar

# 5. Notify via MAKO
# Strips the .css extension for a cleaner notification title
THEME_DISPLAY="${SELECTED_STYLE%.css}"
notify-send -a "Waybar" "Waybar Theme 🌸" "Switched to: <b>$THEME_DISPLAY</b>" -t 2500 -i preferences-desktop-theme
