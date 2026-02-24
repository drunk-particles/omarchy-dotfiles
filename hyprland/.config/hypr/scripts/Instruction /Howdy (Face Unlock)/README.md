# Howdy Face Unlock Setup – ThinkPad T14 Gen 2 (Arch Linux + Hyprland)

This guide recreates the exact working setup for **Howdy** (facial recognition like Windows Hello) on my ThinkPad T14 Gen 2 (IR camera + emitter on `/dev/video2`).  
Tested with howdy-git, hyprlock, fprintd fingerprint as fallback, and sudo/lock screen integration.

**Hardware notes**:
- IR camera: `/dev/video2` (confirmed with `v4l2-ctl --list-devices`)
- Emitter activation required via `sudo linux-enable-ir-emitter`
- Works in good lighting; add multiple face models for reliability
- Snappy detection: ~1–3 seconds after trigger (with Enter press in hyprlock)

## Prerequisites 📜

#### 1. **Install packages** (AUR helpers like `yay`/paru):

```bash
yay -S howdy-git linux-enable-ir-emitter
# If you want fingerprint too (later step):
yay -S fprintd
```

###### `linux-enable-ir-emitter` , this shi* is important, U know why, right? damnation...ChatGPT, wasted my whole day...not telling me about this 💢

#### 2. **Enable IR emitter** (critical – LEDs won't turn on without this):

```
sudo linux-enable-ir-emitter configure   # Run in large terminal; follow prompts (selects /dev/video2 usually)
sudo systemctl enable --now linux-enable-ir-emitter.service
```

You know, lists of devices...haha, it's usually video2, but if it's not...verify it.

```
v4l2-ctl --list-devices
```

###### Reboot or test: 

```
mpv av://v4l2:/dev/video2
```

##### Or,

```
ffplay /dev/video2
```

##### IR LEDs should light up, grayscale face visible. 🥳

#### 3. Confirm IR device (persistent path optional but better)

```
ls -l /dev/v4l/by-path/*video*   # Pick one ending in -index2 or matching video2
```



### Howdy Configuration (Snappy & Reliable) 👀

Run:

```
sudo howdy config
```

##### Replace with this exact config (optimized for speed + reliability on T14 Gen 2):

```
# Howdy config file - Optimized for snappy unlock on ThinkPad T14 Gen 2
# Press CTRL + X to save in nano

[core]
# Print that face detection is being attempted
detection_notice = false

# Print that face detection has timed out
timeout_notice = true

# Do not print anything when a face verification succeeds
no_confirmation = true

# When a user without a known face model tries to use this script, don't show an error but fail silently
suppress_unknown = true

# Disable Howdy in remote shells
abort_if_ssh = true

# Disable Howdy if lid is closed (good for laptops)
abort_if_lid_closed = true

# Disable howdy in the PAM (command-line howdy still works)
disabled = false

# Use CNN instead of HOG (keep false - power hungry, not needed)
use_cnn = false

# Workaround for lock screens like hyprlock (off = reliable, needs Enter; input/native can break trigger)
workaround = off

[video]
# Certainty threshold (lower = faster/more forgiving; 5.0 for snappy speed)
certainty = 5.0

# Seconds to search before timeout (higher avoids quick fails → feels faster)
timeout = 4

# Your IR device (persistent path better long-term, but /dev/video2 is fine if stable)
device_path = /dev/video2

# Warn if device not found
warn_no_device = true

# Scale down feed (lower = faster processing; 240 is good speed trade-off)
max_height = 240

# Frame size (smaller = faster; 320x320 works on most ThinkPads for speed)
frame_width = 320
frame_height = 320

# Ignore very dark frames (lower skips more flicker → smoother)
dark_threshold = 50

# Recorder plugin (opencv default works well)
recording_plugin = opencv

# FFMPEG only - leave defaults
device_format = v4l2

# OPENCV only - MJPEG force usually not needed
force_mjpeg = false

# Exposure/FPS (leave -1 for auto; manual only if issues)
exposure = -1
device_fps = -1

# Rotation check (0 = landscape only, good for laptop cam)
rotate = 0

[snapshots]
# No snapshots (privacy + disk space)
save_failed = false
save_successful = false

[rubberstamps]
# Extra checks after recognition (keep disabled unless you need anti-spoofing)
enabled = false

# Stamp rules (example commented)
stamp_rules =
	# nod		5s		failsafe     min_distance=12

[debug]
# Keep off unless troubleshooting
end_report = false
verbose_stamps = false
gtk_stdout = false

```

Save & Exit.

## Add Face Models (Do This Multiple Times!)

```
sudo howdy add   # Run 5–10 times: different angles, lighting, glasses/no glasses, distances 40–70 cm (Run some IN DA DARK ENVIROMENT TOO, U WILL THANK ME LATER)
sudo howdy list  # Check them
# Remove bad ones if needed: sudo howdy remove <id>
```

Test Detection:

```
sudo howdy test   # Should be fast (~1–3s) after IR on
```

## 🔑PAM Integration (Face First → Fingerprint → Password)

##### Howdy for Terminal Sudo use case

```
sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak  #Backup the existing config
sudo nano /etc/pam.d/sudo                    #Open it and add the following, at the very top of anything else to have priority
```

Use:

```
#%PAM-1.0
auth      sufficient   /lib/security/pam_howdy.so     # Native from howdy-git
auth      sufficient   pam_fprintd.so
auth      sufficient   pam_unix.so try_first_pass likeauth nullok
auth      include      system-auth
account   include      system-auth
password  include      system-auth
session   include      system-auth
```

Test: 

```
sudo whoami
```

#####  → face scan first (IR on), then finger if fails, then password.

###### If your howdy-git uses Python module: replace with 

```
pam_python.so /lib/security/howdy/pam.py
```

## 🔐 For hyprlock (lock screen)

```
sudo cp /etc/pam.d/hyprlock /etc/pam.d/hyprlock.bak  #backup first, it's better 2b safe 😁
sudo nano /etc/pam.d/hyprlock  # same as before, at the very top before any other "auth" okay??
```

###### Use Same Order:

```
#%PAM-1.0
auth      sufficient   /lib/security/pam_howdy.so
auth      sufficient   pam_fprintd.so
auth      sufficient   pam_unix.so try_first_pass likeauth nullok
auth      include      system-auth
account   include      system-auth
password  include      system-auth
session   include      system-auth
```

Inside `~/.config/hypr/hyprlock.conf` :

```
# FACE RECOGNITION (added section for convenience)

general {
    ignore_empty_input = false   # Allows empty Enter to trigger PAM/Howdy
}
```

###### Add this section to your hyprlock config, below is my hyprlock config currently in use.

```
$hypr = ~/.config/hypr
source = $hypr/colors.conf # for custom color

# GENERAL
general {
  no_fade_in = true
  grace = 1
  disable_loading_bar = false
  hide_cursor = true
  ignore_empty_input = true
  text_trim = true
}

# BACKGROUND
background {
    monitor =
    path = ~/.config/omarchy/current/background
    blur_passes = 2
    contrast = 0.8916
    brightness = 0.7172
    vibrancy = 0.1696
    vibrancy_darkness = 0
}

# ANIMATION
animations {
    animation = fade, 1, 6, default
    animation = fadeIn, 1, 6, default
    animation = fadeOut, 1, 6, default
}

# Lock Icon
label {
    monitor =
    text = <span>👁 </span>
    color = rgba(216, 222, 233, 0.70)
    font_size = 30
    font_family = CaskaydiaMono Nerd Font
    position = 2, -150
    halign = center
    valign = top
}

label {
    monitor =
    text = <span>Show Your Ugly Face</span>
    color = rgba(216, 222, 233, 0.70)
    font_size = 15
    font_family = CaskaydiaMono Nerd Font
    position = 2, -110
    halign = center
    valign = top
}

# TIME HR
label {
    monitor =
    text = cmd[update:1000] echo -e "$(date +"%H")"
    color = rgba(255, 255, 255, 1)
    shadow_pass = 2
    shadow_size = 3
    shadow_color = rgb(0,0,0)
    shadow_boost = 1.2
    font_size = 150
    font_family = CaskaydiaMono Nerd Font
    position = 0, -250
    halign = center
    valign = top
}

# TIME MIN
label {
    monitor =
    text = cmd[update:1000] echo -e "$(date +"%M")"
    color = rgba(255, 255, 255, 1)
    font_size = 150
    font_family = CaskaydiaMono Nerd Font
    position = 0, -420
    halign = center
    valign = top
}

# DATE
label {
    monitor =
    text = cmd[update:1000] echo -e "$(date +"%d %b %A")"
    color = rgba(255, 255, 255, 1)
    font_size = 15
    font_family = CaskaydiaMono Nerd Font
    position = 0, -130
    halign = center
    valign = center
}

# MUSIC INFO
label {
    monitor =
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/song-status.sh)"
    color = rgba(242, 243, 244, 0.75)
    font_size = 14
    font_family = CaskaydiaMono Nerd Font
    position = 20, 512
    halign = left
    valign = center
}

# BATTERY INFO
label {
    monitor =
    text = cmd[update:1000] echo -e "$(~/.config/hypr/bin/battery-status.sh)"
    color = rgba(255, 255, 255, 1)
    font_size = 15
    font_family = CaskaydiaMono Nerd Font
    position = -93, 512
    halign = right
    valign = center
}

# INPUT FIELD
input-field {
    monitor =
    size = 250, 60
    outline_thickness = 0
    outer_color = rgba(0, 0, 0, 1)
    dots_size = 0.1
    dots_spacing = 1
    dots_center = true
    inner_color = rgba(0, 0, 0, 1)
    font_color = rgba(200, 200, 200, 1)
    fade_on_empty = false
    font_family = CaskaydiaMono Nerd Font
    placeholder_text = <span> Enter Password 󰈷 </span>
    hide_input = false
    position = 0, -470
    halign = center
    valign = center
    zindex = 10
    fade_on_empty = true
}

# FACE RECOGNITION (added section for convenience)
general {
    ignore_empty_input = false   # Allows empty Enter to trigger PAM/Howdy
}

# FINGERPRINT AUTH (corrected syntax)
auth {
    fingerprint {
        enabled = true
    }
}


```

**hyprlock behavior**:

- Wake/lid open → hyprlock shows
- Look at camera → **press Enter** → face scan starts (IR on)
- If face fails → fingerprint LED/prompt
- If both fail → type password
- No true auto-start without Enter (known limitation; see hyprlock #910, howdy #1042)  (A Pity!)

## For SDDM (Simple Desktop Display Manager)

```
sudo cp /etc/pam.d/sddm /etc/pam.d/sddm.bak
sudo nano /etc/pam.d/sddm
```

Add these lines at the very top:

```
auth      sufficient /lib/security/pam_howdy.so
auth      sufficient pam_unix.so try_first_pass likeauth nullok   # ← fallback
```



## Fingerprint Setup (Fallback)

```
fprintd-enroll   # Follow prompts; enroll multiple fingers
```

## Troubleshooting

- **No IR LEDs**: Restart sudo systemctl restart linux-enable-ir-emitter.service; rerun configure.

- **Slow detection**: Add more models, lower certainty to 4.8, smaller frames (test 280x280 if emitter unhappy).

- **hyprlock no scan without Enter**: Normal for now; workaround=input sometimes breaks trigger.

- **Breaks after update**: 

  ```
  yay -Syu howdy-git python-dlib opencv
  ```

- **Logs**: journalctl -f during auth; look for pam_howdy / fprintd errors.

## Final Confirmation (What Worked for Me)

- sudo: Face first, fast unlock.
- hyprlock: Enter → face → fingerprint → password.
- IR reliable after emitter service.
- Snappy with certainty=5.0, smaller frames, good models.

Re-setup: Follow steps 1–4, paste configs, add models, test sudo/hyprlock.

Good luck future me! 🚀
