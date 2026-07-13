#!/bin/sh
# Runs after Aether applies a theme: point wall.png at the new wallpaper,
# show it via awww, and reload Hyprland so borders re-read colors.toml.
wp=$(ls -t "$HOME/.config/aether/theme/backgrounds/"* 2>/dev/null | head -n1)
[ -n "$wp" ] && ln -sf "$wp" "$HOME/Pictures/wallpapers/wall.png"
awww img "$HOME/Pictures/wallpapers/wall.png" --transition-type grow --transition-pos center
hyprctl reload
"$HOME/.local/bin/waybar-theme-icons" >/dev/null 2>&1   # per-theme logo/workspace icons
pkill -SIGUSR2 waybar   # reload config + style with the new palette
"$HOME/.local/bin/papirus-accent" >/dev/null 2>&1   # tint folder icons to the accent
"$HOME/.local/bin/game-icons" >/dev/null 2>&1       # per-theme badged app icon set
"$HOME/.local/bin/game-cursors" >/dev/null 2>&1     # per-theme recolored cursor set
"$HOME/.local/bin/eza-theme" >/dev/null 2>&1        # per-theme eza (ls) colors
