#!/usr/bin/env bash
# ============================================================
#  mako-setup.sh — Runs on Hyprland startup
#  1. Ensures mako-inject.sh hook is in omarchy-theme-set
#  2. Runs mako-inject.sh for the current session
# ============================================================

THEME_SET_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-theme-set"
INJECT_SCRIPT="$HOME/.config/hypr/scripts/mako-inject.sh"
MARKER="mako-inject.sh"

# --- INJECT HOOK INTO omarchy-theme-set ----------------------
if [[ -f "$THEME_SET_SCRIPT" ]] && ! grep -qF "$MARKER" "$THEME_SET_SCRIPT"; then
    # Insert before omarchy-restart-mako
    sed -i "s|omarchy-restart-mako|# Inject custom.conf include into mako theme config before restarting\nbash \"$INJECT_SCRIPT\"\nomarchy-restart-mako|" "$THEME_SET_SCRIPT"
fi

# --- RUN INJECT FOR CURRENT SESSION --------------------------
bash "$INJECT_SCRIPT"