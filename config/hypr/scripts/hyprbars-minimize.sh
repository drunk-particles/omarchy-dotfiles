#!/bin/bash

# A simple example script to minimize/restore windows by moving them to a special workspace
# You might need a specific script that works with how Hyprland handles minimization
# This example uses a "minimized" special workspace

if [ "$(hyprctl -j activewindow | gojq -r '.workspace.name')" = "special:minimized" ]; then
    hyprctl dispatch togglespecialworkspace minimized
else
    hyprctl dispatch movetoworkspace special:minimized
fi
