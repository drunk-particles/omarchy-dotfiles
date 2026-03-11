#!/bin/bash
# battery-monitor — UPower-based battery event daemon
# Requires: upower, pactl, pw-play, notify-send, brightnessctl, powerprofilesctl

# ── Configuration ────────────────────────────────────────────────────────────
readonly CRITICAL_LEVEL=5        # % — begin nagging + dim screen
readonly SOUND_DIR="$HOME/.config/hypr/assets/sounds"
readonly FLAG_FILE="/run/user/$UID/battery_alert_notified"
readonly BAT_DEV=$(upower -e | grep 'BAT' | head -n 1)

# ── Runtime State ─────────────────────────────────────────────────────────────
LAST_STATUS=""
CRITICAL_TRIGGERED=false
LAST_NAG_CAPACITY=100            # Start high so first drop triggers correctly

# ── Cleanup ───────────────────────────────────────────────────────────────────
trap 'rm -f "$FLAG_FILE"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────

# play_alert <sound_file> [volume%]
# Temporarily unmutes + sets volume, plays sound, then restores prior state.
play_alert() {
    local sound_file="$1"
    local target_vol="${2:-80%}"

    local original_vol original_mute
    original_vol=$(pactl get-sink-volume @DEFAULT_SINK@ \
        | awk -F '/' '{print $2}' | head -n 1 | tr -d '% ')
    original_mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

    pactl set-sink-mute   @DEFAULT_SINK@ 0
    pactl set-sink-volume @DEFAULT_SINK@ "$target_vol"

    pw-play "$sound_file"   # blocking — restore happens only after it finishes

    pactl set-sink-volume @DEFAULT_SINK@ "${original_vol}%"
    [[ "$original_mute" == "yes" ]] && pactl set-sink-mute @DEFAULT_SINK@ 1
}

# quiet_vol — returns 50% between midnight–6 AM, 70% otherwise
quiet_vol() {
    local hour
    hour=$(date +%H)
    (( hour >= 0 && hour < 6 )) && echo "50%" || echo "70%"
}

# ── Core Event Handler ────────────────────────────────────────────────────────
process_event() {
    local battery_info status capacity
    battery_info=$(upower -i "$BAT_DEV") || return
    status=$(echo   "$battery_info" | awk '/state/      {print $2}')
    capacity=$(echo "$battery_info" | awk '/percentage/ {print $2}' | tr -d '%')

    # Guard: skip if data is missing or non-numeric
    [[ -z "$status" || -z "$capacity" || ! "$capacity" =~ ^[0-9]+$ ]] && return

    # ── 1. Plug / Unplug transition ──────────────────────────────────────────
    if [[ "$status" != "$LAST_STATUS" ]]; then
        case "$status" in
            charging)
                notify-send -u normal "Power Connected" "Charging (${capacity}%)" \
                    -i battery-charging
                powerprofilesctl set balanced 2>/dev/null
                rm -f "$FLAG_FILE"
                CRITICAL_TRIGGERED=false
                LAST_NAG_CAPACITY=100
                play_alert "$SOUND_DIR/charging.wav" "$(quiet_vol)"
                ;;
            discharging)
                notify-send -u normal "On Battery" "Power-saver active" \
                    -i battery-caution
                powerprofilesctl set power-saver 2>/dev/null
                ;;
        esac
        LAST_STATUS="$status"
    fi

    # ── 2. Critical nag (discharging only) ───────────────────────────────────
    [[ "$status" != "discharging" ]] && return

    if (( capacity <= CRITICAL_LEVEL )); then
        if [[ "$CRITICAL_TRIGGERED" == false ]] || (( capacity < LAST_NAG_CAPACITY )); then
            notify-send -u critical "CRITICAL: ${capacity}%" "Plug in now!" \
                -i battery-empty

            # Dim screen only on the very first critical trigger
            [[ "$CRITICAL_TRIGGERED" == false ]] && brightnessctl set 10%

            play_alert "$SOUND_DIR/low-battery.wav"

            CRITICAL_TRIGGERED=true
            LAST_NAG_CAPACITY=$capacity
            touch "$FLAG_FILE"
        fi
    fi
}

# ── Entry Point ───────────────────────────────────────────────────────────────
if [[ -z "$BAT_DEV" ]]; then
    echo "battery-monitor: no battery device found via upower" >&2
    exit 1
fi

process_event   # Immediate check at startup

upower --monitor | while read -r _line; do
    process_event
done