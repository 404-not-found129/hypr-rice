
# Show system info in new terminal windows (skip nested shells)
if [[ "$TERM" == "xterm-kitty" || "$TERM" == "alacritty" ]] && [[ $SHLVL -eq 1 ]]; then
    fastfetch
fi
