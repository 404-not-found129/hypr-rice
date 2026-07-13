
# eza (modern ls) — icons need a Nerd Font (JetBrainsMono Nerd Font is set)
[[ -f ~/.config/eza/colors.sh ]] && source ~/.config/eza/colors.sh   # theme colors
if command -v eza >/dev/null; then
    eza_opts='--icons=auto --group-directories-first'
    alias ls="eza $eza_opts"
    alias ll="eza $eza_opts -l --git --header"
    alias la="eza $eza_opts -la --git --header"
    alias lt="eza $eza_opts --tree --level=2"
    alias lt3="eza $eza_opts --tree --level=3"
    alias lg="eza $eza_opts -l --git --git-ignore"
    alias lls='command ls --color=auto'   # original ls, if ever needed
fi

# Show system info in new terminal windows (skip nested shells)
if [[ "$TERM" == "xterm-kitty" || "$TERM" == "alacritty" ]] && [[ $SHLVL -eq 1 ]]; then
    fastfetch
fi
