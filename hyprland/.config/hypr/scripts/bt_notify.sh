#!/usr/bin/env bash
# =============================================================================
# Bluetooth notifier – minimal style: "Device Name 80%" only on connect
# Deduplicated, low-battery warning separate
# =============================================================================

set -u -e -o pipefail

# ─── Config ───────────────────────────────────────────────────────
readonly LOW_BATTERY_THRESHOLD=20
readonly ICON_CONNECTED="bluetooth"
readonly ICON_DISCONNECTED="bluetooth-disabled"
readonly ICON_LOW_BATTERY="battery-low"

last_handled=0
readonly DEBOUNCE_SECONDS=3

# ─── Helpers ──────────────────────────────────────────────────────
get_first_connected_mac() {
    bluetoothctl devices Connected 2>/dev/null | awk 'NR==1 {print $2}'
}

get_device_name() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null \
        | awk -F': *' '/^Name:/ {print $2; exit}'
}

get_battery_percentage() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null \
        | awk -F'[()]' '/Battery Percentage:/ {gsub(/[^0-9]/,"",$2); print $2; exit}'
}

notify() {
    local urgency="$1" icon="$2" title="$3" body="$4"
    notify-send ${urgency:+-u "$urgency"} ${icon:+-i "$icon"} "$title" "$body"
}

handle_event() {
    local now mac name batt msg

    now=$(date +%s)
    (( now - last_handled < DEBOUNCE_SECONDS )) && return 0
    last_handled=$now

    mac=$(get_first_connected_mac)

    if [[ -z "$mac" ]]; then
        notify "low" "$ICON_DISCONNECTED" \
            "Bluetooth Disconnected" "A device was disconnected"
        return 0
    fi

    name=$(get_device_name "$mac")
    [[ -z "$name" ]] && name="Bluetooth device"

    batt=$(get_battery_percentage "$mac")

    if [[ -n "$batt" ]]; then
        msg="$name $batt%"

        # Main connect notification – just name + percentage
        notify "" "$ICON_CONNECTED" "$msg" ""

        if (( batt <= LOW_BATTERY_THRESHOLD )); then
            notify "critical" "$ICON_LOW_BATTERY" \
                "Low Battery" "$name is at ${batt}% – charge soon!"
        fi
    else
        # No battery reported → just show device name
        notify "" "$ICON_CONNECTED" "$name" ""
    fi
}

# ─── Main ─────────────────────────────────────────────────────────
echo "→ Minimal Bluetooth notifier running (shows \"Name %\" only)"

dbus-monitor --system \
    "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" 2>/dev/null |
while read -r line; do
    if [[ "$line" =~ "'Connected':"[[:space:]]*"<'true'>" ]]; then
        sleep 1
        handle_event
    fi
done