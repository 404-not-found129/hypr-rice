#!/bin/bash
#
# hypr-rice theme-set hook for Omarchy (installed by install-omarchy.sh into
# ~/.config/omarchy/hooks/theme-set.d/). Omarchy itself handles colors,
# wallpaper, borders, terminals and the bar; this adds the rice's extras:
# the video behind the chosen background (see bin/live-wallpaper), and badged app icons, recolored
# cursors and tinted Papirus folders on the rice themes -- restoring
# Omarchy's own icons/cursor on any other theme.
#
theme=$1
RICE_THEMES=(elden-ring ashen-flame god-of-war fallout cyberpunk-2077 tokyo-night gruvbox catppuccin-mocha)

bin=$HOME/.local/bin
icons=$HOME/.local/share/icons
export HYPR_RICE_THEME_FILE=$HOME/.local/state/omarchy/current/theme.name
export HYPR_RICE_COLORS=$HOME/.local/state/omarchy/current/theme/colors.toml

# Omarchy has already picked the theme's background; play the video behind it
"$bin/live-wallpaper" sync

apply() {
  # Serialize: switching themes quickly must not run two icon builds at once
  exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hypr-rice-theme.lock"
  flock 9

  if [[ " ${RICE_THEMES[*]} " == *" $theme "* ]]; then
    "$bin/papirus-accent"
    "$bin/game-icons"
    "$bin/game-cursors"
  else
    # game-icons mirrors its badged icons into hicolor (the fallback every
    # toolkit checks), so they'd outlive the theme unless removed here.
    for size in 64x64 128x128; do
      for f in "$icons"/Aether-Game-*/"$size"/apps/*.png; do
        [[ -e $f ]] && rm -f "$icons/hicolor/$size/apps/${f##*/}"
      done
    done
    gtk-update-icon-cache -f -t "$icons/hicolor"

    cursor=$(cat "$HOME/.local/state/hypr-rice/cursor-theme" 2>/dev/null || echo default)
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor"
    hyprctl setcursor "$cursor" 24
  fi

  "$bin/eza-theme"  # ls colors follow every theme's accent, rice or not
}

# Icon generation takes a few seconds on first use of a theme; don't hold up
# the rest of `omarchy theme set` for it.
apply >/dev/null 2>&1 </dev/null &
disown
