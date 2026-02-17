#!/usr/bin/env bash

# === CONFIG ===
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "Unknown")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds/"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
THUMB_SIZE="128"

mkdir -p "$CACHE_DIR"

# Collect wallpapers with full paths + basenames
declare -A wp_map   # basename_without_ext -> full_path
mapfile -t WALLPAPERS < <(find -L "$USER_BG_DIR" "$THEME_BG_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print 2>/dev/null | sort -u)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send -u normal "Wallpaper Selector" "No wallpapers found for $THEME_NAME" -t 4000
    exit 1
fi

# Build list for fuzzel + map for lookup
entries=""
for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    name="${base%.*}"   # without extension – change to "$base" if you want .jpg shown

    # Optional: generate thumb anyway (in case you want notify icon)
    thumb="$CACHE_DIR/${base}.thumb.jpg"
    if [ ! -f "$thumb" ]; then
        ffmpeg -y -i "$wp" \
            -vf "scale=$THUMB_SIZE:$THUMB_SIZE:force_original_aspect_ratio=decrease,pad=$THUMB_SIZE:$THUMB_SIZE:(ow-iw)/2:(oh-ih)/2" \
            -frames:v 1 "$thumb" >/dev/null 2>&1
    fi

    wp_map["$name"]="$wp"
    entries+="$name\n"
done

# Launch fuzzel
selected=$(echo -en "$entries" | \
    fuzzel --dmenu \
           -p "Pick wallpaper ($THEME_NAME) " \
           --lines=10 \
           --width=50 \
           --cache=/dev/null)

if [ -z "$selected" ]; then
    exit 0
fi

# Lookup full path by selected name
NEW_WP="${wp_map[$selected]}"

if [ -z "$NEW_WP" ] || [ ! -f "$NEW_WP" ]; then
    notify-send -u critical "Wallpaper Selector" "Couldn't find file for: $selected" -t 3000
    exit 1
fi

# Apply
swww img "$NEW_WP" \
    --transition-type wipe \
    --transition-angle 45 \
    --transition-pos "$(hyprctl cursorpos)" \
    --transition-fps 90 \
    --transition-step 35 \
    --transition-duration 1.5 \
    --resize fit

# Notify (using cached thumb if exists)
THUMB_NOTIFY="${CACHE_DIR}/$(basename "$NEW_WP").thumb.jpg"
[ -f "$THUMB_NOTIFY" ] || THUMB_NOTIFY="/usr/share/icons/Adwaita/48x48/places/folder-pictures-symbolic.symbolic.png"

notify-send -u normal "Wallpaper Changed" "$selected ($THEME_NAME)" -t 2500 -i "$THUMB_NOTIFY"