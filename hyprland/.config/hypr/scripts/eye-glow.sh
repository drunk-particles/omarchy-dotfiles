#!/usr/bin/env bash
while true; do
    # Subtle hue shift in blue-cyan range (very gentle "pulse")
    r=80
    g=$((140 + (RANDOM % 40)))   # 140-180
    b=$((220 + (RANDOM % 35)))   # 220-255
    alpha="0.45"                 # keep glow transparent

    echo "<span foreground='#${r}${g}${b}'>👁</span>"
    sleep 3                      # change every 3s – slow and subtle
done