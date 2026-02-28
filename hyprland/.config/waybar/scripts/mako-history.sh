#!/bin/bash
# Get last 10 dismissed notifications
# Requires: jq
history=$(makoctl history | jq -r '.data[:10] | .[] | "• \(.summary.data)"' | sed 's/"/\\"/g')

if [ -z "$history" ]; then 
    history="No notification history"
fi

# We leave "text" empty because the icon is now in the Waybar config
printf '{"text": "", "tooltip": "%s"}\n' "$history"
