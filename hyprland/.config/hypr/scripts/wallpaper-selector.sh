#!/usr/bin/env bash
# ============================================================
#  wallpaper-pick.sh — Rofi wallpaper gallery (5×3)
# ============================================================

THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "default")
THEME_BG_DIR="$HOME/.config/omarchy/current/theme/backgrounds"
USER_BG_DIR="$HOME/.config/omarchy/backgrounds/$THEME_NAME"
CURRENT_BG_LINK="$HOME/.config/omarchy/current/background"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs/$THEME_NAME"
THUMB_SIZE="400"

# --- COLOR EXTRACTION ----------------------------------------
CSS_FILE="$HOME/.config/omarchy/current/theme/walker.css"
get_color() {
    grep -m1 "@define-color $1 " "$CSS_FILE" 2>/dev/null \
        | awk '{print $3}' | tr -d ';'
}

C_BASE=$(   get_color "base"         ); C_BASE="${C_BASE:-#1e1e2e}"
C_BORDER=$( get_color "border"       ); C_BORDER="${C_BORDER:-#45475a}"
C_SEL=$(    get_color "selected-box" ); C_SEL="${C_SEL:-#5f8fdb}"

mkdir -p "$CACHE_DIR"

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
        # Scale to square (ensures enough pixels), then crop to 16:9
        ffmpeg -y -i "$wp" \
            -vf "scale=${THUMB_SIZE}:${THUMB_SIZE},crop=${THUMB_SIZE}:$((THUMB_SIZE*9/16))" \
            -frames:v 1 "$thumb" >/dev/null 2>&1 || continue
    fi
    wp_map["$base"]="$wp"
    entries+="${base}\0icon\x1f${thumb}\n"
done

# --- LAUNCH ROFI ---------------------------------------------
selected=$(echo -en "$entries" | rofi -dmenu \
    -i -show-icons -no-custom \
    -theme "$ROFI_THEME" \
    -theme-str "
        window { background-color: ${C_BASE}99; border-color: ${C_BORDER}; }
        element selected        { border-color: ${C_SEL}; }
        element selected.normal { border-color: ${C_SEL}; }
        element selected.urgent { border-color: ${C_SEL}; }
        element selected.active { border-color: ${C_SEL}; }
    ")

[[ -z "$selected" ]] && exit 0
NEW_WP="${wp_map[$selected]}"
[[ ! -f "$NEW_WP" ]] && exit 1

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