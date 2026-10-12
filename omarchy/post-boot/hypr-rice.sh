#!/bin/bash
# hypr-rice post-boot hook for Omarchy: start the current theme's video
# wallpaper once the desktop is up (installed by install-omarchy.sh).
"$HOME/.local/bin/live-wallpaper" >/dev/null 2>&1 </dev/null &
disown
