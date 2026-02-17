#!/bin/bash

# Configuration
LOW_BATT_LIMIT=20

# Function to handle notifications
handle_bt_event() {
    # Get MAC of the first connected/recently disconnected device
    MAC=$(bluetoothctl devices Connected | awk '{print $2}' | head -n 1)
    
    # If no connected device is found, we assume a disconnection event occurred
    if [ -z "$MAC" ]; then
        # Optional: You can try to find the last known device name from 'bluetoothctl devices'
        notify-send -u low -i bluetooth-disabled "Bluetooth Disconnected" "Device has been disconnected"
        return
    fi

    # Fetch device information
    INFO=$(bluetoothctl info "$MAC")
    NAME=$(echo "$INFO" | grep "Name:" | cut -d ' ' -f 2-)
    BATT=$(echo "$INFO" | grep "Battery Percentage:" | awk -F '[()]' '{print $2}' | tr -d '%')

    # Connection Notification
    if [ -n "$BATT" ]; then
        notify-send -i bluetooth "Bluetooth Connected" "$NAME: $BATT%"
        
        # Low Battery Check
        if [ "$BATT" -le "$LOW_BATT_LIMIT" ]; then
            notify-send -u critical -i battery-low "Low Battery Alert" "$NAME is at $BATT%!"
        fi
    else
        notify-send -i bluetooth "Bluetooth Connected" "$NAME connected"
    fi
}

# Listen for DBus property changes (Connect/Disconnect)
# Use 2>/dev/null to ignore the "AccessDenied" warning; eavesdropping still works
dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" 2>/dev/null | 
while read -r line; do
    # Trigger on 'Connected' status changes
    if echo "$line" | grep -q "Connected"; then
        # Wait briefly for Bluetooth services to sync status
        sleep 1
        handle_bt_event
    fi
done
