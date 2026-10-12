# Shared by install.sh and install-omarchy.sh. Expects REPO, info and warn.

# Only install what isn't already satisfied: an installed package that
# *provides* a dep (e.g. ttf-jetbrains-mono-nerd-basic) counts, so pacman
# never hits a conflict prompt that --noconfirm would answer "no" to.
missing() { pacman -T "$@" || true; }

# Sets aur_helper to yay or paru, bootstrapping yay if neither is installed.
ensure_aur_helper() {
  aur_helper=""
  for h in yay paru; do command -v "$h" >/dev/null && aur_helper=$h && break; done
  if [[ -z $aur_helper ]]; then
    info "No AUR helper found — bootstrapping yay..."
    local tmp
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    aur_helper=yay
  fi
}

# papirus-folders + an ACL on the Papirus themes, so folder icons can be
# re-tinted to each theme's accent without a password prompt.
install_papirus_folders() {
  if [[ ! -x $HOME/.local/bin/papirus-folders ]]; then
    info "Installing papirus-folders (folder icons tinted per theme)..."
    curl -fsSL -o "$HOME/.local/bin/papirus-folders" \
      https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders
    chmod +x "$HOME/.local/bin/papirus-folders"
  fi
  info "Granting write access to Papirus themes (needed for folder tinting)..."
  sudo setfacl -R -m "u:$USER:rwX" /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light
}

# Bundled collections first, then anything missing from wallhaven.
install_wallpapers() {
  if [[ -d $REPO/wallpapers/collections ]]; then
    info "Installing bundled wallpaper collections..."
    mkdir -p "$HOME/Pictures/wallpapers/collections"
    cp -rn "$REPO/wallpapers/collections/." "$HOME/Pictures/wallpapers/collections/"
  fi

  info "Fetching any missing wallpapers from wallhaven..."
  local fails=0 theme url dir f
  while read -r theme url; do
    [[ -z $theme || $theme == \#* ]] && continue
    dir="$HOME/Pictures/wallpapers/collections/$theme"
    mkdir -p "$dir"
    f="$dir/$(basename "$url")"
    [[ -s $f ]] && continue
    if curl -fsSL --retry 3 -o "$f" "$url" && magick identify "$f" >/dev/null 2>&1; then
      printf '  %s\n' "$(basename "$f")"
    else
      rm -f "$f"; fails=$((fails+1)); warn "failed: $url"
    fi
  done < "$REPO/wallpapers/manifest.txt"
  [[ $fails -gt 0 ]] && warn "$fails wallpaper(s) failed to download — re-run the installer later to retry."

  # bundled wallpaper + shared collection symlink
  mkdir -p "$HOME/Pictures/wallpapers/collections/catppuccin-mocha"
  cp -n "$REPO/wallpapers/catppuccin-evening-sky.png" "$HOME/Pictures/wallpapers/collections/catppuccin-mocha/" 2>/dev/null || true
  ln -sfn elden-ring "$HOME/Pictures/wallpapers/collections/ashen-flame"

  # Drop-in folders for video wallpapers (played by bin/live-wallpaper)
  local t
  for t in "$REPO/config/aether/blueprints/"*.json; do
    mkdir -p "$HOME/Pictures/wallpapers/live/$(basename "$t" .json)"
  done
}
