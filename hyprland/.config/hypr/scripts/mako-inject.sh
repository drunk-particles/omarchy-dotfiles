#!/usr/bin/env bash
# ============================================================
#  mako-inject.sh — Ensures both core.ini and custom.conf
#  are included in the active theme's mako.ini
# ============================================================

MAKO_INI="$HOME/.config/omarchy/current/theme/mako.ini"
CORE_LINE="include=~/.local/share/omarchy/default/mako/core.ini"
CUSTOM_LINE="include=~/.config/mako/custom.conf"

if [[ ! -f "$MAKO_INI" ]]; then
    exit 0
fi

NEEDS_CORE=0
NEEDS_CUSTOM=0

grep -qF "$CORE_LINE"   "$MAKO_INI" || NEEDS_CORE=1
grep -qF "$CUSTOM_LINE" "$MAKO_INI" || NEEDS_CUSTOM=1

if [[ $NEEDS_CORE -eq 1 || $NEEDS_CUSTOM -eq 1 ]]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    BLOCK="# [auto-injected by mako-inject.sh on $TIMESTAMP]\n"
    [[ $NEEDS_CUSTOM -eq 1 ]] && BLOCK+="${CUSTOM_LINE}\n"
    [[ $NEEDS_CORE   -eq 1 ]] && BLOCK+="${CORE_LINE}\n"
    sed -i "1s|^|${BLOCK}\n|" "$MAKO_INI"
fi

makoctl reload 2>/dev/null || true