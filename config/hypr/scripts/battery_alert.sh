#!/bin/bash

# Configuration
CRITICAL_LEVEL=5
HIBERNATE_LEVEL=2
SOUND_DIR="$HOME/Music/system"
FLAG_FILE="/run/user/$UID/battery_alert_notified"

# Initial state
last_status=$(upower -i $(upower -e | grep 'BAT') | grep "state" | awk '{print $2}')

while true; do
  # Use Omarchy's accurate rounding script
  capacity=$(omarchy-battery-remaining)
  status=$(upower -i $(upower -e | grep 'BAT') | grep "state" | awk '{print $2}')

  # 1. INSTANT PLUG-IN/UNPLUG LOGIC
  if [ "$status" != "$last_status" ]; then
    if [ "$status" == "charging" ]; then
      pw-play "$SOUND_DIR/power-charge.mp3" &
      powerprofilesctl set balanced # Auto-switch to balanced on AC
      rm -f "$FLAG_FILE" # Reset flag when plugged in
    else
      powerprofilesctl set power-saver # Save juice immediately on unplug
    fi
    last_status="$status"
  fi

  # 2. DISCHARGING ALERTS
  if [ "$status" == "discharging" ]; then
    
    # Critical Alert (Only if not already notified)
    if [ "$capacity" -le "$CRITICAL_LEVEL" ] && [ ! -f "$FLAG_FILE" ]; then
      notify-send -u critical "   CRITICAL: ${capacity}%" "Plug in immediately!"
      
      # Loud Alert Logic
      v=$(pactl get-sink-volume @DEFAULT_SINK@ | awk -F '/' '{print $2}' | head -n 1 | sed 's/[% ]//g')
      pactl set-sink-mute @DEFAULT_SINK@ 0
      pactl set-sink-volume @DEFAULT_SINK@ 110%
      pw-play "$SOUND_DIR/low-battery.mp3"
      pactl set-sink-volume @DEFAULT_SINK@ "${v}%"
      
      touch "$FLAG_FILE" # Prevent sound from repeating every loop
      brightnessctl set 10%
    
    # Emergency Hibernate
    elif [ "$capacity" -le "$HIBERNATE_LEVEL" ]; then
      systemctl hibernate
    fi
  fi

  sleep 2 # Efficient polling rate
done
