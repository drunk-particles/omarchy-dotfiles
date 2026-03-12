#!/usr/bin/env bash
# ============================================================
#  mako-inject.sh — Ensures custom.conf is included in core.ini
# ============================================================

CORE_INI="$HOME/.local/share/omarchy/default/mako/core.ini"
INJECT_LINE="include=~/.config/mako/custom.conf"

if [[ ! -f "$CORE_INI" ]]; then
    exit 0
fi

if ! grep -qF "$INJECT_LINE" "$CORE_INI"; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    sed -i "1s|^|# [auto-injected by mako-inject.sh on $TIMESTAMP]\n${INJECT_LINE}\n\n|" "$CORE_INI"
    makoctl reload 2>/dev/null || true
fi