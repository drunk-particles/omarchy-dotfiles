#!/usr/bin/env python3

import subprocess
import json
import sys
import os
import tempfile

GRADIENT_COLORS = [
    '#3e8fb0', '#9ccfd8', '#c4a7e7', '#ea9a97', '#f6c177', '#eb6f92'
]
BARS = " ▂▃▄▅▆▇█"
ASCII_MAX_RANGE = 9

# CAVA configuration content
CAVA_CONFIG_CONTENT = """
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
ascii_max_range = 9
"""

def generate_pango_gradient(line_of_data):
    bars_data = line_of_data.strip().split(';')
    pango_output = ""
    
    # Check if this specific frame is silent
    is_silent_frame = all(val == '0' for val in bars_data if val)
    
    if is_silent_frame:
        return None # Return None to indicate a silent frame

    for bar_str in bars_data:
        try:
            bar_value = int(bar_str)
            if bar_value == 0:
                color_index = 0
            else:
                color_index = min(int(bar_value * len(GRADIENT_COLORS) / ASCII_MAX_RANGE), len(GRADIENT_COLORS) - 1)
            color = GRADIENT_COLORS[color_index]
            char = BARS[min(bar_value, len(BARS) - 1)]
            pango_output += f'<span foreground="{color}">{char}</span>'
        except ValueError:
            continue
    return pango_output

def run_cava():
    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.conf') as f:
        f.write(CAVA_CONFIG_CONTENT)
        temp_config_path = f.name
    
    process = None
    # Hysteresis variables
    silent_frames_threshold = 120 # Hide after ~2 seconds of true silence (at 60fps)
    silent_frames_count = 0

    try:
        process = subprocess.Popen(
            ['cava', '-p', temp_config_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        for line in process.stdout:
            pango_text = generate_pango_gradient(line)
            
            if pango_text is None:
                silent_frames_count += 1
            else:
                silent_frames_count = 0 # Reset counter if there is any sound
            
            # If we haven't hit the silence threshold yet, show "empty" bars instead of hiding
            if pango_text is None and silent_frames_count < silent_frames_threshold:
                # Show 8 flat dots or empty bars so the box stays visible during dips
                pango_text = f'<span foreground="{GRADIENT_COLORS[0]}">        </span>'

            # If silence persists longer than threshold, send empty string to hide box
            if silent_frames_count >= silent_frames_threshold:
                json_output = json.dumps({"text": ""})
            else:
                json_output = json.dumps({"text": pango_text})
            
            print(json_output)
            sys.stdout.flush()

    except FileNotFoundError:
        print(json.dumps({"text": "CAVA not found!"}))
        sys.stdout.flush()
    except Exception as e:
        print(json.dumps({"text": "ERR"}))
        sys.stdout.flush()
    finally:
        if os.path.exists(temp_config_path):
            os.remove(temp_config_path)
        if process:
            process.kill()

if __name__ == "__main__":
    run_cava()
