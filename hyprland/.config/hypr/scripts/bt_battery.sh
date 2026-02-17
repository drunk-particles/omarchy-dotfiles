#!/bin/bash

# Configuration
LOW_BATTERY_THRESHOLD=20
CHECK_INTERVAL=60 # seconds

while true; do
    # Get the MAC address of the first connected device
    DEVICE_MAC=$(bluetoothctl devices Connected | awk '{print $2}' | head -n 1)

    if [ -n "$DEVICE_MAC" ]; then
        # Fetch Name and Battery Percentage
        DEVICE_INFO=$(bluetoothctl info "$DEVICE_MAC")
        NAME=$(echo "$DEVICE_INFO" | grep "Name:" | cut -d ' ' -f 2-)
        BATT=$(echo "$DEVICE_INFO" | grep "Battery Percentage:" | awk -F '[()]' '{print $2}' | tr -d '%')

        # 1. Send Initial Connection Notification (if just connected)
        if [ "$LAST_MAC" != "$DEVICE_MAC" ]; then
            notify-send -i bluetooth "Bluetooth Connected" "$NAME is connected\nBattery: ${BATT:-Unknown}%"
            LAST_MAC=$DEVICE_MAC
            HAS_WARNED=false
        fi

        # 2. Low Battery Alert
        if [[ -n "$BATT" && "$BATT" -le "$LOW_BATTERY_THRESHOLD" && "$HAS_WARNED" = false ]]; then
            notify-send -u critical -i battery-low "Low Battery Alert" "$NAME is at $BATT%"
            HAS_WARNED=true
        fi
    else
        LAST_MAC=""
        HAS_WARNED=false
    fi

    sleep "$CHECK_INTERVAL"
done
