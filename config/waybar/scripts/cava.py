#!/usr/bin/env python3

import subprocess
import json
import sys
import os
import tempfile

GRADIENT_COLORS = [
    '#3e8fb0', '#9ccfd8', '#c4a7e7', '#ea9a97', '#f6c177', '#eb6f92'
]
# BARS="⡀⡄⡆⡇⣇⣧⣷⣿⡿⣟⣯⣾⢿⣻⣽⣷"
BARS = " ▂▃▄▅▆▇█"
ASCII_MAX_RANGE = 9

# CAVA configuration content
CAVA_CONFIG_CONTENT = """
[general]
bars = 12
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
    # Create a temporary config file
    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.conf') as f:
        f.write(CAVA_CONFIG_CONTENT)
        temp_config_path = f.name
    
    process = None
    try:
        # Start CAVA using the temporary config file path
        process = subprocess.Popen(
            ['cava', '-p', temp_config_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        # Read CAVA's stdout line by line forever
        for line in process.stdout:
            pango_text = generate_pango_gradient(line)
            json_output = json.dumps({"text": pango_text})
            print(json_output)
            sys.stdout.flush()

    except FileNotFoundError:
        print(json.dumps({"text": "CAVA not found!", "tooltip": "Please install CAVA"}))
        sys.stdout.flush()
    except Exception as e:
        stderr_output = process.stderr.read() if process else "N/A"
        error_msg = f"Script Error: {str(e)} STDERR: {stderr_output}"
        print(json.dumps({"text": "ERR", "tooltip": error_msg}))
        sys.stdout.flush()
    finally:
        # Clean up the temporary file
        if os.path.exists(temp_config_path):
            os.remove(temp_config_path)
        if process:
            process.kill()

if __name__ == "__main__":
    run_cava()