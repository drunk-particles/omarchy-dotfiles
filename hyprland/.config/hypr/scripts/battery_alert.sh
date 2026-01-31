#!/bin/bash

# --- Configuration ---
CRITICAL_LEVEL=5
HIBERNATE_LEVEL=2
SOUND_DIR="$HOME/Music/system"
FLAG_FILE="/run/user/$UID/battery_alert_notified"
BAT_DEV=$(upower -e | grep 'BAT' | head -n 1)

# Persistent state variables
LAST_STATUS=""
CRITICAL_TRIGGERED=false
LAST_NAG_CAPACITY=0

# Cleanup flag on script exit
trap "rm -f $FLAG_FILE" EXIT

play_alert() {
    local sound_file="$1"
    local target_vol="80%"
    
    # Save current volume and mute state
    local original_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk -F '/' '{print $2}' | head -n 1 | sed 's/[% ]//g')
    local original_mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

    # Alert state: Unmute and set to 80%
    pactl set-sink-mute @DEFAULT_SINK@ 0
    pactl set-sink-volume @DEFAULT_SINK@ "$target_vol"
    
    pw-play "$sound_file"
    
    # Restore original state
    pactl set-sink-volume @DEFAULT_SINK@ "${original_vol}%"
    [[ "$original_mute" == "yes" ]] && pactl set-sink-mute @DEFAULT_SINK@ 1
}

process_event() {
    local battery_info=$(upower -i "$BAT_DEV")
    local status=$(echo "$battery_info" | awk '/state/ {print $2}')
    local capacity=$(echo "$battery_info" | awk '/percentage/ {print $2}' | tr -d '%')

    # 1. Plug/Unplug Instant Response
    if [[ "$status" != "$LAST_STATUS" ]]; then
        if [[ "$status" == "charging" ]]; then
            notify-send -u normal "Power Connected" "Charging ($capacity%)" -i battery-charging
            powerprofilesctl set performance 2>/dev/null
            rm -f "$FLAG_FILE"
            CRITICAL_TRIGGERED=false
            LAST_NAG_CAPACITY=0
            play_alert "$SOUND_DIR/power-charge.mp3" &
        elif [[ "$status" == "discharging" ]]; then
            notify-send -u normal "On Battery" "Power-saver active" -i battery-caution
            powerprofilesctl set power-saver 2>/dev/null
        fi
        LAST_STATUS="$status"
    fi

    # 2. Critical Nag Logic (Fires on every 1% drop)
    if [[ "$status" == "discharging" ]]; then
        if [[ "$capacity" -le "$CRITICAL_LEVEL" ]]; then
            if [[ "$CRITICAL_TRIGGERED" == false ]] || [[ "$capacity" -lt "$LAST_NAG_CAPACITY" ]]; then
                notify-send -u critical "CRITICAL: ${capacity}%" "Plug in now!" -i battery-empty
                
                # Only dim the screen the very first time it hits critical
                if [[ "$CRITICAL_TRIGGERED" == false ]]; then
                    brightnessctl set 10%
                fi
                
                play_alert "$SOUND_DIR/low-battery.mp3" &
                
                CRITICAL_TRIGGERED=true
                LAST_NAG_CAPACITY="$capacity"
                touch "$FLAG_FILE"
            fi
        # 3. Hibernate Safety
        elif [[ "$capacity" -le "$HIBERNATE_LEVEL" ]]; then
            systemctl hibernate
        fi
    fi
}

# Run once at boot
process_event

# Monitor hardware events with zero-lag loop
upower --monitor | while read -r line; do
    process_event
done
