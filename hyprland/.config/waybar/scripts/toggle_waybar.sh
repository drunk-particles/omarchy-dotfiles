#!/bin/bash

# Updated path to point to your new subfolder
STYLE_DIR="$HOME/.config/waybar/css"
# The main directory where waybar looks for style.css
WAYBAR_DIR="$HOME/.config/waybar"

STYLES=("style1.css" "style2.css" "style3.css")
STATE_FILE="/tmp/waybar_style_state"

# Read current state (index), default to 0
CUR_INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Calculate next index (0, 1, 2)
NEXT_INDEX=$(( (CUR_INDEX + 1) % 3 ))

# Link the selected style from the /css folder to the main waybar folder
ln -sf "$STYLE_DIR/${STYLES[$NEXT_INDEX]}" "$WAYBAR_DIR/style.css"

# Save new state
echo "$NEXT_INDEX" > "$STATE_FILE"

# Restart Waybar
omarchy-restart-waybar
