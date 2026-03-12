#!/usr/bin/env bash
# ============================================================
#  wallpaper-pick.sh — Optimized for Leaf Aesthetic
# ============================================================

THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "default")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME"
CURRENT_BG_LINK="$HOME/.config/omarchy/current/background"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs/$THEME_NAME"
THUMB_SIZE="500"

# --- COLOR EXTRACTION ----------------------------------------
CSS_FILE="$HOME/.config/omarchy/current/theme/walker.css"
get_color() {
    grep -m1 "@define-color $1 " "$CSS_FILE" 2>/dev/null \
        | awk '{print $3}' | tr -d ';'
}
C_BASE=$(  get_color "base" ); C_BASE="${C_BASE:-#1e1e2e}"
# Lighten the border here to match your Rasi (White with 13% opacity)
C_BORDER_LIGHT="#ffffff22" 

# --- HYPRLAND METRICS ----------------------------------------
# We lock col_count to 5 to match your fixed-columns: true in Rasi
col_count=5

mkdir -p "$CACHE_DIR"
if pgrep -x rofi >/dev/null 2>&1; then pkill -x rofi; exit 0; fi

# --- FIND WALLPAPERS -----------------------------------------
declare -A seen
declare -a WALLPAPERS
while IFS= read -r wp; do
    fname=$(basename "$wp")
    if [[ -z "${seen[$fname]+x}" ]]; then
        seen[$fname]=1
        WALLPAPERS+=("$wp")
    fi
done < <(find -L "$USER_BG_DIR" "$THEME_BG_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.mp4" \) \
    2>/dev/null | sort)

[[ ${#WALLPAPERS[@]} -eq 0 ]] && { notify-send "Wallpaper Picker" "No files found."; exit 1; }

# --- BUILD THUMBNAILS ----------------------------------------
declare -A wp_map
entries=""
current_wall=$(basename "$(readlink -f "$CURRENT_BG_LINK" 2>/dev/null)")

for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    thumb="$CACHE_DIR/${base}.sqre.png"
    if [[ ! -f "$thumb" ]]; then
        ffmpeg -y -i "$wp" -vf "select=eq(n\,0),scale=${THUMB_SIZE}:${THUMB_SIZE}:force_original_aspect_ratio=increase,crop=${THUMB_SIZE}:${THUMB_SIZE}" -vframes 1 "$thumb" >/dev/null 2>&1 || continue
    fi
    wp_map["$base"]="$wp"
    entries+="${base}\0icon\x1f${thumb}\n"
done

# --- LAUNCH ROFI ---------------------------------------------
# Updated override to use the lightened border color
r_override="window { border-color: ${C_BORDER_LIGHT}; } listview { columns: ${col_count}; }"

selected=$(echo -en "$entries" | rofi -dmenu -i -show-icons -no-custom -theme "$ROFI_THEME" -theme-str "$r_override" -select "$current_wall")
[[ -z "$selected" ]] && exit 0

NEW_WP="${wp_map[$selected]}"
[[ ! -f "$NEW_WP" ]] && exit 1

# --- REFINED MP4 CONVERSION ----------------------------------
if [[ "$NEW_WP" == *.mp4 || "$NEW_WP" == *.MP4 ]]; then
    CONVERTED_GIF="$CACHE_DIR/$(basename "$NEW_WP").gif"
    if [[ ! -f "$CONVERTED_GIF" ]]; then
        notify-send "Wallpaper Picker" "Optimizing Live Wallpaper..."
        
        # This filters for quality, sets 24fps, and crops to 16:9 center automatically
        ffmpeg -i "$NEW_WP" -vf "fps=24,scale=1920:-1:flags=lanczos,crop=1920:1080,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=sierra2_4a" "$CONVERTED_GIF" >/dev/null 2>&1
    fi
    TARGET_WP="$CONVERTED_GIF"
else
    TARGET_WP="$NEW_WP"
fi

# --- APPLY ---------------------------------------------------
ln -nsf "$TARGET_WP" "$CURRENT_BG_LINK"

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
    uwsm-app -- swww-daemon &
    sleep 0.3
fi

# Transition duration set to 1.2s for a snappier feel
setsid uwsm-app -- swww img "$CURRENT_BG_LINK" \
    --transition-type grow \
    --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" \
    --transition-fps 120 \
    --transition-duration 1.2 \
    --resize crop &
disown

command -v wallust >/dev/null 2>&1 && wallust run "$NEW_WP" || true

# --- NOTIFY --------------------------------------------------
WP_NAME=$(basename "${NEW_WP%.*}")
THUMB_NOTIFY="$CACHE_DIR/$(basename "$NEW_WP").sqre.png"
notify-send -i "$THUMB_NOTIFY" "$THEME_NAME" "$WP_NAME"