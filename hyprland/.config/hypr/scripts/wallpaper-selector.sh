#!/usr/bin/env bash
# ============================================================
#  wallpaper-selector.sh — HyDE-faithful wallpaper selector
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
C_BASE=$(  get_color "base"         ); C_BASE="${C_BASE:-#1e1e2e}"
C_SEL=$(   get_color "selected-box" ); C_SEL="${C_SEL:-#58586b}"
C_FG=$(    get_color "text"         ); C_FG="${C_FG:-#cdd6f4}"

# --- HYPRLAND METRICS ----------------------------------------
hypr_border=$(hyprctl -j getoption decoration:rounding 2>/dev/null \
    | grep -o '"int": [0-9]*' | awk '{print $2}')
hypr_border="${hypr_border:-8}"
elem_border=$((hypr_border * 3))

mon_data=$(hyprctl -j monitors 2>/dev/null)
mon_x_res=$(echo "$mon_data" | jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' 2>/dev/null)
mon_scale=$(echo "$mon_data" | jq '.[] | select(.focused==true) | .scale' 2>/dev/null | sed "s/\.//")
mon_x_res="${mon_x_res:-1920}"
mon_scale="${mon_scale:-100}"
mon_x_res=$(( mon_x_res * 100 / mon_scale ))

font_scale=10
elm_width=$(( (22 + 8 + 5) * font_scale ))
max_avail=$(( mon_x_res - (4 * font_scale) ))
col_count=$(( max_avail / elm_width ))
col_count=5

mkdir -p "$CACHE_DIR"

# --- TOGGLE: kill if already running -------------------------
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

# --- BUILD THUMBNAILS (ImageMagick like HyDE) ----------------
entries=""
current_wall=$(basename "$(readlink -f "$CURRENT_BG_LINK" 2>/dev/null)")

for wp in "${WALLPAPERS[@]}"; do
    base=$(basename "$wp")
    thumb="$CACHE_DIR/${base}.sqre"

    if [[ ! -f "$thumb" ]]; then
        if command -v magick &>/dev/null; then
            magick "$wp"[0] -strip \
                -thumbnail ${THUMB_SIZE}x${THUMB_SIZE}^ \
                -gravity center \
                -extent ${THUMB_SIZE}x${THUMB_SIZE} \
                "${thumb}.png" 2>/dev/null && mv "${thumb}.png" "$thumb" || continue
        else
            ffmpeg -y -i "$wp" \
                -vf "scale=${THUMB_SIZE}:${THUMB_SIZE}:force_original_aspect_ratio=increase,crop=${THUMB_SIZE}:${THUMB_SIZE}" \
                -frames:v 1 "${thumb}.png" >/dev/null 2>&1 && mv "${thumb}.png" "$thumb" || continue
        fi
    fi

    label="${base%.*}"
    entries+="${label}:::${wp}:::${thumb}\0icon\x1f${thumb}\n"
done

# --- LAUNCH ROFI ---------------------------------------------
r_override="
    * { main-bg: ${C_BASE}55; main-fg: ${C_FG}ff; select-bg: ${C_SEL}; select-fg: ${C_FG}ff; }
    window { background-color: ${C_BASE}55; }
    listview { columns: ${col_count}; spacing: 5em; }
    element { border-radius: ${elem_border}px; orientation: vertical; }
    element-icon { size: 22em; border-radius: 0em; }
    element-text { padding: 1em; }
"

selected=$(echo -en "$entries" | rofi -dmenu \
    -i -show-icons -no-custom \
    -display-column-separator ":::" \
    -display-columns 1 \
    -theme "$ROFI_THEME" \
    -theme-str "$r_override" \
    -select "${current_wall%.*}")

[[ -z "$selected" ]] && exit 0

selected_path=$(awk -F ':::' '{print $2}' <<<"$selected")
NEW_WP="$selected_path"
[[ -z "$NEW_WP" || ! -f "$NEW_WP" ]] && exit 1

# --- APPLY WALLPAPER (HyDE swww style) -----------------------
ln -nsf "$NEW_WP" "$CURRENT_BG_LINK"

if ! swww query &>/dev/null; then
    swww-daemon --format xrgb &
    disown
    sleep 0.3
    swww restore
fi

swww img "$(readlink -f "$CURRENT_BG_LINK")" \
    --transition-bezier .43,1.19,1,.4 \
    --transition-type    grow \
    --transition-duration 1.5 \
    --transition-fps     60 \
    --invert-y \
    --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" &
disown

command -v wallust >/dev/null 2>&1 && wallust run "$NEW_WP" || true