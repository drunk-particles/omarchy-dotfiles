local mp = require 'mp'

function seek_based_on_position()
    local pos = mp.get_property_native("mouse-pos")
    if not pos then return end

    local width = mp.get_property_number("osd-width") or 1280  -- fallback
    local x = pos.x / width  -- 0.0 = left edge → 1.0 = right edge

    if x > 0.85 then          -- only extreme right (last 15%) → seek forward
        mp.commandv("seek", 10)
        mp.osd_message("→ +10s")
    elseif x < 0.15 then      -- only extreme left (first 15%) → seek backward
        mp.commandv("seek", -10)
        mp.osd_message("← -10s")
    else                      -- everything else (central 70%) → fullscreen toggle
        mp.commandv("cycle", "fullscreen")
    end
end

mp.add_key_binding("MBTN_LEFT_DBL", "position-aware-doubleclick", seek_based_on_position)