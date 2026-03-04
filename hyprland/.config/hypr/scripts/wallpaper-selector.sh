#!/usr/bin/env bash
# ============================================================
#  wallpaper-pick.sh — HyDE-style horizontal bar picker
# ============================================================

THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "default")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME"
CURRENT_BG_LINK="$HOME/.config/omarchy/current/background"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs/$THEME_NAME"
THUMB_W="225"
THUMB_H="400"

# --- COLOR EXTRACTION (from walker.css) ----------------------
CSS_FILE="$HOME/.config/omarchy/current/theme/walker.css"
get_color() {
    grep -m1 "@define-color $1 " "$CSS_FILE" 2>/dev/null \
        | awk '{print $3}' | tr -d ';'
}
C_BASE=$(   get_color "base"   ); C_BASE="${C_BASE:-#0d0d0d}"
C_BORDER=$( get_color "border" ); C_BORDER="${C_BORDER:-#45475a}"

# --- HYPRLAND BORDER RADIUS (like HyDE does it) --------------
hypr_border=$(hyprctl -j getoption decoration:rounding 2>/dev/null \
    | grep -o '"int": [0-9]*' | awk '{print $2}')
hypr_border="${hypr_border:-8}"
hypr_width=$(hyprctl -j getoption general:border_size 2>/dev/null \
    | grep -o '"int": [0-9]*' | awk '{print $2}')
hypr_width="${hypr_width:-2}"
elem_border=$(( hypr_border == 0 ? 5 : hypr_border ))

mkdir -p "$CACHE_DIR"

# Toggle: kill if already running
if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi
    exit 0
fi

# --- FIND WALLPAPERS (deduplicated by filename) ---------------
declare -A seen
declare -a WALLPAPERS

while IFS= read -r wp; do
    fname=$(basename "$wp")
    if [[ -z "${seen[$fname]+x}" ]]; then
        seen[$fname]=1
        WALLPAPERS+=("$wp")
    fi
done < <(find -L "$USER_BG_DIR" "$THEME_BG_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    2>/dev/null | sort)

[[ ${#WALLPAPERS[@]} -eq 0 ]] && {
    notify-send "Wallpaper Picker" "No wallpapers found."
    exit 1
}

# --- BUILD THUMBNAILS & ENTRIES ------------------------------
declare -A wp_map
entries=""

for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    thumb="$CACHE_DIR/${base}.png"
    if [[ ! -f "$thumb" ]]; then
        # Portrait crop: scale to fill, then crop to 9:16
        ffmpeg -y -i "$wp" \
            -vf "scale=${THUMB_W}:${THUMB_H}:force_original_aspect_ratio=increase,crop=${THUMB_W}:${THUMB_H}" \
            -frames:v 1 "$thumb" >/dev/null 2>&1 || continue
    fi
    label="${base%.*}"
    wp_map["$label"]="$wp"
    entries+="${label}\0icon\x1f${thumb}\n"
done

# --- LAUNCH ROFI (HyDE-style dynamic overrides) --------------
selected=$(echo -en "$entries" | rofi -dmenu \
    -i -show-icons -no-custom \
    -theme "$ROFI_THEME" \
    -theme-str "
        window { background-color: ${C_BASE}cc; }
        element { border-radius: ${elem_border}px; }
        element-icon { border-radius: ${elem_border}px; }
    ")

[[ -z "$selected" ]] && exit 0
NEW_WP="${wp_map[$selected]}"
[[ -z "$NEW_WP" || ! -f "$NEW_WP" ]] && exit 1

# --- APPLY WALLPAPER -----------------------------------------
ln -nsf "$NEW_WP" "$CURRENT_BG_LINK"

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
    uwsm-app -- swww-daemon &
    sleep 0.3
fi

setsid uwsm-app -- swww img "$CURRENT_BG_LINK" \
    --transition-type     grow \
    --transition-pos      "$(hyprctl cursorpos)" \
    --transition-fps      120 \
    --transition-duration 1.2 \
    --resize crop &
disown

command -v wallust >/dev/null 2>&1 && wallust run "$NEW_WP" || true