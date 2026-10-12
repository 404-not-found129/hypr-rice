#!/bin/bash
# hypr-rice post-boot hook for Omarchy (installed by install-omarchy.sh):
# play the current background's video and follow background changes made
# from Omarchy's background switcher.
setsid "$HOME/.local/bin/live-wallpaper" watch >/dev/null 2>&1 </dev/null &
