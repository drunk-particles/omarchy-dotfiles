#!/usr/bin/env bash

# --- 1. CONFIG ---
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "default")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds/"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
CURRENT_BG_LINK="$HOME/.config/omarchy/current/background"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs/$THEME_NAME"
THUMB_SIZE="200"

mkdir -p "$CACHE_DIR"

# --- 2. FIND WALLPAPERS ---
mapfile -t WALLPAPERS < <(find -L "$USER_BG_DIR" "$THEME_BG_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print 2>/dev/null | sort -u)

# --- 3. PREP ENTRIES ---
declare -A wp_map
entries=""
for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    thumb="$CACHE_DIR/${base}.png"
    if [ ! -f "$thumb" ]; then
        ffmpeg -y -i "$wp" -vf "scale='if(gt(iw,ih),-1,$THUMB_SIZE)':'if(gt(iw,ih),$THUMB_SIZE,-1)',crop=$THUMB_SIZE:$THUMB_SIZE" -frames:v 1 "$thumb" >/dev/null 2>&1 || continue
    fi
    wp_map["$base"]="$wp"
    entries+="$base\0icon\x1f$thumb\n"
done

# --- 4. REDUCED HEIGHT SELECTOR ---
# Reduced width to 40% and limited listview to 2 rows
selected=$(echo -en "$entries" | \
    rofi -dmenu \
         -p "   $THEME_NAME" \
         -i -show-icons -no-custom \
         -theme-str '
            window { width: 40%; border: 2px; border-radius: 12px; background-color: #1e1e2e; }
            listview { columns: 3; lines: 2; spacing: 10px; padding: 10px; fixed-columns: true; fixed-height: false; }
            element { orientation: vertical; padding: 5px; border-radius: 8px; }
            element-icon { size: 100px; horizontal-align: 0.5; }
            element-text { horizontal-align: 0.5; font: "JetBrainsMono Nerd Font 9"; }
            inputbar { padding: 8px; }
         ')

[[ -z "$selected" ]] && exit 0
NEW_WP="${wp_map[$selected]}"

# --- 5. APPLY ---
if [ -f "$NEW_WP" ]; then
    ln -nsf "$NEW_WP" "$CURRENT_BG_LINK"
    pkill -x swww 2>/dev/null
    setsid uwsm-app -- swww img "$CURRENT_BG_LINK" \
        --transition-type grow --transition-pos "$(hyprctl cursorpos)" \
        --transition-fps 120 --transition-duration 1.2 --resize crop &
    
    # Sync system colors
    if command -v wallust >/dev/null 2>&1; then
        wallust run "$NEW_WP"
    fi

    notify-send -u normal "Wallpaper Set" "$selected" -i "$CACHE_DIR/${selected}.png"
fi
