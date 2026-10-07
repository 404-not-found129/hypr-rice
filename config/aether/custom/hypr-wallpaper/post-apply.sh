#!/bin/sh
# Runs after Aether applies a theme (or wallcycle a wallpaper). Everything you
# see changes in one coordinated transition, Omarchy-style:
#   1. the playing video becomes a still of its current frame (invisible),
#   2. the new wallpaper is revealed with a slanted wipe while the bar and
#      window borders switch to the new colors at the same moment,
#   3. the new video takes over from the exact frame the reveal ended on,
# and the work you don't see (icon, cursor and folder recolors) runs after.

# Aether starts this hook without waiting for it, so quick successive applies
# (e.g. tapping Super+Right) would run hooks on top of each other. Run them
# one at a time; each run reads the then-current theme, so the last wins.
exec 8>"${XDG_RUNTIME_DIR:-/tmp}/hypr-rice-post-apply.lock"
flock 8

BIN="$HOME/.local/bin"
DURATION=1.0
# slanted soft-edged wipe, ease-in-out-cubic -- the feel of Omarchy's
# background reveal (the curve puts the visible sweep in the middle ~0.45 s)
TRANSITION="--transition-type wipe --transition-angle 30 --transition-duration $DURATION
            --transition-fps 60 --transition-bezier .65,0,.35,1"

wp=$(ls -t "$HOME/.config/aether/theme/backgrounds/"* 2>/dev/null | head -n1)
[ -n "$wp" ] && ln -sf "$wp" "$HOME/Pictures/wallpapers/wall.png"
"$BIN/waybar-theme-icons" >/dev/null 2>&1    # new bar icons, before the bar restarts

# 1. moving video -> still of its current frame
"$BIN/livewall" freeze >/dev/null 2>&1

# 2. reveal + new colors, together
# shellcheck disable=SC2086
awww img "$HOME/Pictures/wallpapers/wall.png" $TRANSITION &
hyprctl reload >/dev/null 2>&1                # borders re-read colors.toml
"$BIN/bar-swap" >/dev/null 2>&1 &             # bar crossfades to the new theme
sleep "$DURATION"

# 3. the new wallpaper's video (if any) takes over from its poster frame
"$BIN/livewall" sync >/dev/null 2>&1
wait

# off-screen work
"$BIN/papirus-accent" >/dev/null 2>&1        # tint folder icons to the accent
"$BIN/game-icons" >/dev/null 2>&1            # per-theme badged app icon set
"$BIN/game-cursors" >/dev/null 2>&1          # per-theme recolored cursor set
"$BIN/eza-theme" >/dev/null 2>&1             # per-theme eza (ls) colors
"$BIN/color-scheme-sync" >/dev/null 2>&1     # light/dark for GTK, portal, browsers
