#!/usr/bin/env bash

# === CONFIG ===
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "Unknown")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds/"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
THUMB_SIZE="128"

mkdir -p "$CACHE_DIR"

# Merge wallpapers, prefer user overrides
mapfile -t WALLPAPERS < <(find -L "$USER_BG_DIR" "$THEME_BG_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print 2>/dev/null | sort -u)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send -u normal "Wallpaper Selector" "No wallpapers found for $THEME_NAME" -t 4000
    exit 1
fi

# Build list + map
declare -A wp_map
entries=""
for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    name="${base%.*}"

    # Generate PNG thumb for better compatibility
    thumb="$CACHE_DIR/${base}.thumb.png"
    if [ ! -f "$thumb" ]; then
        ffmpeg -y -i "$wp" \
            -vf "scale=$THUMB_SIZE:$THUMB_SIZE:force_original_aspect_ratio=decrease,pad=$THUMB_SIZE:$THUMB_SIZE:(ow-iw)/2:(oh-ih)/2" \
            -frames:v 1 "$thumb" >/dev/null 2>&1 || continue
    fi

    # Absolute path for icon (fallback if realpath fails)
    abs_thumb=$(realpath "$thumb" 2>/dev/null || echo "$thumb")

    wp_map["$name"]="$wp"
    entries+="$name\0icon\x1f$abs_thumb\n"
done

# Launch fuzzel (no --icon-size)
selected=$(echo -en "$entries" | \
    fuzzel --dmenu \
           -p "Pick wallpaper ($THEME_NAME) " \
           --lines=10 \
           --width=60 \
           --cache=/dev/null)

if [ -z "$selected" ]; then
    exit 0
fi

# Lookup path
NEW_WP="${wp_map[$selected]}"

if [ -z "$NEW_WP" ] || [ ! -f "$NEW_WP" ]; then
    notify-send -u critical "Wallpaper Selector" "Couldn't find file for: $selected" -t 3000
    exit 1
fi

# Update symlink
ln -nsf "$NEW_WP" "$CURRENT_BACKGROUND_LINK"

# Apply with swww
pkill -x swww 2>/dev/null
setsid uwsm-app -- swww img "$CURRENT_BACKGROUND_LINK" \
    --transition-type random \
    --transition-angle "$(shuf -i 0-359 -n 1)" \
    --transition-pos "$(hyprctl cursorpos)" \
    --transition-fps 120 \
    --transition-step 45 \
    --transition-duration 2 \
    --resize crop >/dev/null 2>&1 &

# Notify
THUMB_NOTIFY="${CACHE_DIR}/$(basename "$NEW_WP").thumb.png"
[ -f "$THUMB_NOTIFY" ] || THUMB_NOTIFY="/usr/share/icons/Adwaita/48x48/places/folder-pictures-symbolic.symbolic.png"

notify-send -u normal "Wallpaper Changed" "$selected ($THEME_NAME)" -t 2500 -i "$THUMB_NOTIFY"