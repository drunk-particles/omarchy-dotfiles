#!/usr/bin/env bash
# =============================================================================
# Bluetooth notifier – uses bluetoothctl monitor
# =============================================================================

set -u

readonly LOW_BATTERY_THRESHOLD=20
readonly ICON_CONNECTED="bluetooth"
readonly ICON_DISCONNECTED="bluetooth-disabled"
readonly ICON_LOW_BATTERY="battery-low"

last_handled=0
readonly DEBOUNCE_SECONDS=3

get_first_connected_mac() {
    bluetoothctl devices Connected 2>/dev/null | awk 'NR==1 {print $2}'
}

get_device_name() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null \
        | awk -F': *' '/^\s*Name:/ {print $2; exit}'
}

get_battery_percentage() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null \
        | awk -F'[()]' '/Battery Percentage:/ {gsub(/[^0-9]/,"",$2); print $2; exit}'
}

handle_connect() {
    local now mac name batt msg
    now=$(date +%s)
    (( now - last_handled < DEBOUNCE_SECONDS )) && return 0
    last_handled=$now

    sleep 1  # give bluetoothctl time to update device info
    mac=$(get_first_connected_mac)
    [[ -z "$mac" ]] && return 0

    name=$(get_device_name "$mac")
    [[ -z "$name" ]] && name="Bluetooth device"

    batt=$(get_battery_percentage "$mac")

    if [[ -n "$batt" ]]; then
        msg="$name ${batt}%"
        notify-send -i "$ICON_CONNECTED" "$msg"
        if (( batt <= LOW_BATTERY_THRESHOLD )); then
            notify-send -u critical -i "$ICON_LOW_BATTERY" \
                "Low Battery" "$name is at ${batt}% – charge soon!"
        fi
    else
        notify-send -i "$ICON_CONNECTED" "$name" "Connected"
    fi
}

handle_disconnect() {
    notify-send -u low -i "$ICON_DISCONNECTED" "Bluetooth" "Device disconnected"
}

echo "→ Bluetooth notifier running"

while true; do
    bluetoothctl monitor 2>/dev/null | while read -r line; do
        if [[ "$line" =~ "Connected: yes" ]]; then
            handle_connect
        elif [[ "$line" =~ "Connected: no" ]]; then
            handle_disconnect
        fi
    done
    sleep 2
done
