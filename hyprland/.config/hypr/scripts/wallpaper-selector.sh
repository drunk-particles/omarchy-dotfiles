#!/usr/bin/env bash

# --- 1. CONFIG ---
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "default")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds/"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
CURRENT_BG_LINK="$HOME/.config/omarchy/current/background"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs/$THEME_NAME"
THUMB_SIZE="200"

# --- COLOR EXTRACTION (The "Magic" Part) ---
# This looks at your walker.css and pulls the Zen Garden colors
CSS_FILE="$HOME/.config/omarchy/current/theme/walker.css"
get_color() {
    grep "@define-color $1" "$CSS_FILE" | awk '{print $3}' | sed 's/;//'
}

C_BASE=$(get_color "base" || echo "#051A18")
C_TEXT=$(get_color "text" || echo "#E0E4DE")
C_BORDER=$(get_color "border" || echo "#355A53")
C_SEL_BOX=$(get_color "selected-box" || echo "#006F92")
C_SEL_TEXT=$(get_color "selected-text" || echo "#C3EED2")

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
# We use the C_ variables here to style Rofi dynamically
selected=$(echo -en "$entries" | \
    rofi -dmenu \
         -p "Theme: $THEME_NAME" \
         -i -show-icons -no-custom \
         -theme-str '
            window { 
                width: 45%; 
                border: 2px; 
                border-radius: 12px; 
                background-color: '"$C_BASE"'; 
                border-color: '"$C_BORDER"'; 
            }
            mainbox { children: [ "textbox-prompt-colon", "listview" ]; background-color: transparent; }
            textbox-prompt-colon {
                expand: false;
                str: "    Theme: '"$THEME_NAME"'";
                padding: 12px;
                text-color: '"$C_SEL_TEXT"';
                background-color: '"$C_BORDER"';
                horizontal-align: 0.5;
                font: "JetBrainsMono Nerd Font Bold 10";
            }
            listview { 
                columns: 4; lines: 2; spacing: 10px; padding: 15px; 
                fixed-columns: false; fixed-height: false;
                background-color: transparent;
            }
            element { 
                orientation: vertical; padding: 10px; border-radius: 8px; 
                background-color: transparent;
                text-color: '"$C_TEXT"';
            }
            element selected { 
                background-color: '"$C_SEL_BOX"'; 
                text-color: '"$C_SEL_TEXT"';
            }
            element-icon { size: 110px; horizontal-align: 0.5; background-color: transparent; }
            element-text { 
                horizontal-align: 0.5; font: "JetBrainsMono Nerd Font 9"; padding: 5px 0 0 0; 
                text-color: inherit;
            }
            inputbar { enabled: false; }
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
    
    if command -v wallust >/dev/null 2>&1; then
        wallust run "$NEW_WP"
    fi

    #notify-send -u normal "Wallpaper Set" "$selected" -i "$CACHE_DIR/${selected}.png"
fi
