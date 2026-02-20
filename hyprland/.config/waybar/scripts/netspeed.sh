#!/bin/bash
# Get initial bytes
PREV_RX=$(cat /sys/class/net/wlan0/statistics/rx_bytes)
PREV_TX=$(cat /sys/class/net/wlan0/statistics/tx_bytes)

while true; do
  sleep 1
  # Get new bytes
  CURR_RX=$(cat /sys/class/net/wlan0/statistics/rx_bytes)
  CURR_TX=$(cat /sys/class/net/wlan0/statistics/tx_bytes)
  
  # Calculate speed in bytes
  DIFF_RX=$((CURR_RX - PREV_RX))
  DIFF_TX=$((CURR_TX - PREV_TX))
  
  # Convert to KB or MB for display
  if [ $DIFF_RX -gt $DIFF_TX ]; then
    echo " $(numfmt --to=iec $DIFF_RX)/s"
  else
    echo " $(numfmt --to=iec $DIFF_TX)/s"
  fi

  PREV_RX=$CURR_RX
  PREV_TX=$CURR_TX
done
