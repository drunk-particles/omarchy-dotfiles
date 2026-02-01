#!/usr/bin/env python3
import subprocess, json, sys, os, tempfile

# 2026 Nebula Palette (Polished)
# Muted, sophisticated tones for 2026
GRADIENT_COLORS = [
    '#b7bdf8', # Lavender
    '#c6a0f6', # Mauve
    '#f5bde6', # Pink
    '#91d7e3', # Sky
    '#8bd5ca', # Teal
    '#8aadf4'  # Blue
]

# BARS restored with the baseline character (lower one eighth block)
#BARS = "⣀⡀⡄⡆⡇⣇⣧⣷" 
BARS = "▁▂▃▄▅▆▇█"
# Note: ASCII_MAX_RANGE needs to match the length of BARS minus one
ASCII_MAX_RANGE = 7 

CAVA_CONFIG = """
[general]
bars = 8
framerate = 60
sensitivity = 100
[input]
method = pipewire
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
"""

def generate_pango(line, frame_count):
    bars_data = line.strip().split(';')
    if not bars_data: return None

    pango_output = ""
    for i, bar_str in enumerate(bars_data):
        try:
            val = int(bar_str)
            
            # Use baseline character if value is zero
            char = BARS[0] if val == 0 else BARS[min(val, len(BARS) - 1)]
            
            # Dynamic Color Shifting
            color_step = (i + (frame_count // 10)) % len(GRADIENT_COLORS)
            color = GRADIENT_COLORS[color_step]
            
            pango_output += f'<span foreground="{color}">{char}</span>'
        except (ValueError, IndexError):
            continue
    return pango_output

def run_cava():
    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.conf') as f:
        f.write(CAVA_CONFIG)
        temp_path = f.name
    
    process = None
    frame_count = 0
    silent_frames_threshold = 90 
    silent_frames_count = 0

    try:
        process = subprocess.Popen(
            ['cava', '-p', temp_path],
            stdout=subprocess.PIPE, text=True, bufsize=1
        )
        
        for line in process.stdout:
            frame_count += 1
            pango_text = generate_pango(line, frame_count)
            
            is_silent_frame = all(v == '0' for v in line.strip().split(';') if v)

            if is_silent_frame:
                silent_frames_count += 1
            else:
                silent_frames_count = 0
            
            # If completely silent for 1.5s, send "" to hide the module
            if silent_frames_count >= silent_frames_threshold:
                print(json.dumps({"text": ""}))
            else:
                # Otherwise, send the text (which now includes the baseline)
                print(json.dumps({"text": pango_text}))
            
            sys.stdout.flush()

    except Exception:
        print(json.dumps({"text": ""}))
    finally:
        if os.path.exists(temp_path): os.remove(temp_path)
        if process: process.kill()

if __name__ == "__main__":
    run_cava()
