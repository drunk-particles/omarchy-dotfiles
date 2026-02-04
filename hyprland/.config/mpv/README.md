### 🎬 Premium mpv + uosc config

A minimalist, high-performance **mpv** configuration optimized for **Intel hardware** and **Everforest** aesthetics. This setup features a modern **uosc** interface, automated subtitle workflows, and a custom **position-aware** navigation system.

✨ Highlights

- **Visuals:** `gpu-next` + `ewa_lanczossharp` for elite upscaling and debanding.
- **UI:** Custom uosc build with an **Everforest** theme (`#d3c6aa`).
- **Navigation:** Intelligent double-click zones for seeking vs. fullscreen.
- **Audio:** Dynamic normalization for consistent volume across loud/quiet scenes.
- **Subtitles:** Warm, cinematic gold (`#F7E3AC`) with automated subliminal fetching.

------

#### 🖼️ Preview

| ![img](demo/1.png) | ![img](demo/2.png) |
| ------------------ | ------------------ |



------

#### ⌨️ Smart Navigation & Controls

| Input                     | Action                              |
| :------------------------ | :---------------------------------- |
| **Left Click**            | Play / Pause                        |
| **Right Click**           | Open **uosc** Menu                  |
| **Double Click (Sides)**  | Seek ±10s (Outer 15% of screen)     |
| **Double Click (Center)** | Toggle Fullscreen (Center 70%)      |
| **Scroll Wheel**          | Volume ±2                           |
| **`s` / `v`**             | Cycle Subtitles / Toggle Visibility |
| **`i` / `?`**             | Show Stats / Toggle Stats Overlay   |

------

📦 Requirements

1. #### Core Packages (Arch Linux)

bash

```
# Core & Dependencies
sudo pacman -S mpv python-pip

# AUR: UI & Subtitle Tools
yay -S mpv-uosc-git mpv-thumbfast-git subliminal mpv-autosub-git
```

Use code with caution.



2. #### Performance Script (Omarchy)

This setup includes the **mpv-smart** script for GPU optimization.

- **Path:** `~/.local/share/omarchy/bin/mpv-smart`
- **Setup:** `chmod +x ~/.local/share/omarchy/bin/mpv-smart`

------

#### 🔧 Configuration Logic

- **Video:** Optimized for Intel (VA-API) with safe fallbacks and `target-colorspace-hint=no` to prevent washed-out fullscreen colors.
- **Aesthetics:** `uosc` is configured with a hidden volume bar and a compact, centered control layout for a distraction-free experience.
- **Subtitles:** Integrated `autosub.lua` (powered by `subliminal`) handles fetching missing tracks automatically.

------

#### 📂 Installation

1. Move `mpv.conf`, `input.conf` to `~/.config/mpv/`.
2. Move  `uosc.conf`, `autosub.conf` to  `~/.config/mpv/script-opts`
3. Place `position-seek.lua` and `autosub.lua` in `~/.config/mpv/scripts/`.
4. Enjoy the cleanest media experience on Linux.

------

# Or just place the extracted files inside  `~/.config/mpv/`, that'll do.
