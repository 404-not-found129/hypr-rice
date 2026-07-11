#!/usr/bin/env bash
#
# hypr-rice installer — Hyprland + Aether theme-switching rice
# Arch Linux only. Safe to re-run; existing configs are backed up first.
#
set -Eeuo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLD=$'\e[1m'; RST=$'\e[0m'
info()  { printf '%s[*]%s %s\n' "$GRN" "$RST" "$*"; }
warn()  { printf '%s[!]%s %s\n' "$YLW" "$RST" "$*"; }
die()   { printf '%s[x]%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }
trap 'die "Install failed at line $LINENO. Fix the issue and re-run — the script is idempotent."' ERR

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------- checks ----
[[ -f /etc/arch-release ]] || die "This installer targets Arch Linux (pacman)."
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root (sudo is used where needed)."
command -v sudo >/dev/null || die "sudo is required."

info "This will install packages and place configs for: Hyprland (Lua config),"
info "waybar, alacritty/kitty, Aether theming, theme switcher and wallpaper cycling."
read -rp "Continue? [y/N] " a; [[ ${a,,} == y* ]] || exit 0

# ---------------------------------------------------------- dependencies ----
PACMAN_DEPS=(
  hyprland hyprlock hypridle hyprpicker hyprshot xdg-desktop-portal-hyprland
  hyprpolkitagent waybar alacritty kitty awww grim swaync
  network-manager-applet thunar pavucontrol pamixer wl-clipboard
  papirus-icon-theme ttf-jetbrains-mono-nerd fastfetch btop
  imagemagick curl python acl polkit rofi-wayland git base-devel
)
AUR_DEPS=(
  aether walker-bin wlogout
  elephant-bin elephant-desktopapplications-bin elephant-runner-bin
  elephant-calc-bin elephant-clipboard-bin elephant-files-bin
  elephant-menus-bin elephant-providerlist-bin elephant-symbols-bin
  elephant-websearch-bin
)

info "Installing official packages (pacman)..."
sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

aur_helper=""
for h in yay paru; do command -v "$h" >/dev/null && aur_helper=$h && break; done
if [[ -z $aur_helper ]]; then
  info "No AUR helper found — bootstrapping yay..."
  tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  aur_helper=yay
fi
info "Installing AUR packages ($aur_helper)..."
"$aur_helper" -S --needed --noconfirm "${AUR_DEPS[@]}"

# ------------------------------------------------------------- configs ------
backup() { # backup <path>
  if [[ -e $1 && ! -L $1 ]]; then
    mkdir -p "$BACKUP"
    mv "$1" "$BACKUP/$(basename "$1").$(date +%s)"
    warn "Existing $(basename "$1") moved to $BACKUP"
  fi
}

info "Installing configs (existing ones are backed up to $BACKUP)..."
for d in hypr waybar alacritty kitty swaync walker; do
  backup "$HOME/.config/$d"
  mkdir -p "$HOME/.config/$d"
  cp -r "$REPO/config/$d/." "$HOME/.config/$d/"
done

mkdir -p "$HOME/.config/aether"
cp -r "$REPO/config/aether/custom" "$HOME/.config/aether/"
mkdir -p "$HOME/.config/aether/blueprints"
cp "$REPO/config/aether/blueprints/"*.json "$HOME/.config/aether/blueprints/"

mkdir -p "$HOME/.local/bin"
cp "$REPO/bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"{wallcycle,themeswitch,papirus-accent,waybar-theme-icons} \
         "$HOME/.config/aether/custom/hypr-wallpaper/post-apply.sh"

mkdir -p "$HOME/.config/systemd/user"
cp -r "$REPO/systemd/." "$HOME/.config/systemd/user/"
systemctl --user daemon-reload 2>/dev/null || true

# Point every placeholder at this user's home
grep -rlZ "__HOME__" "$HOME/.config/hypr" "$HOME/.config/waybar" \
  "$HOME/.config/aether" 2>/dev/null | xargs -0 -r sed -i "s|__HOME__|$HOME|g"

# ------------------------------------------------------- papirus folders ----
if [[ ! -x $HOME/.local/bin/papirus-folders ]]; then
  info "Installing papirus-folders (folder icons tinted per theme)..."
  curl -fsSL -o "$HOME/.local/bin/papirus-folders" \
    https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders
  chmod +x "$HOME/.local/bin/papirus-folders"
fi
info "Granting write access to Papirus themes (needed for folder tinting)..."
sudo setfacl -R -m "u:$USER:rwX" /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light

# ----------------------------------------------------------- wallpapers -----
if [[ -d $REPO/wallpapers/collections ]]; then
  info "Installing bundled wallpaper collections..."
  mkdir -p "$HOME/Pictures/wallpapers/collections"
  cp -rn "$REPO/wallpapers/collections/." "$HOME/Pictures/wallpapers/collections/"
fi

info "Fetching any missing wallpapers from wallhaven..."
fails=0
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
[[ $fails -gt 0 ]] && warn "$fails wallpaper(s) failed to download — re-run install.sh later to retry."

# bundled wallpaper + shared collection symlink
mkdir -p "$HOME/Pictures/wallpapers/collections/catppuccin-mocha"
cp -n "$REPO/wallpapers/catppuccin-evening-sky.png" "$HOME/Pictures/wallpapers/collections/catppuccin-mocha/" 2>/dev/null || true
ln -sfn elden-ring "$HOME/Pictures/wallpapers/collections/ashen-flame"

# ------------------------------------------------------------- defaults -----
info "Setting the default theme (elden-ring)..."
printf 'elden-ring' > "$HOME/.config/aether/current-theme"
default_wall="$HOME/Pictures/wallpapers/collections/elden-ring/wallhaven-m9mwqy.jpg"
[[ -s $default_wall ]] || default_wall=$(find "$HOME/Pictures/wallpapers/collections/elden-ring" -type f | head -n1)
mkdir -p "$HOME/Pictures/wallpapers"
ln -sf "$default_wall" "$HOME/Pictures/wallpapers/wall.png"

# GUI wallpaper browser mirror (Aether scans ~/Wallpapers)
if [[ -d $HOME/Wallpapers && ! -L $HOME/Wallpapers ]]; then
  rmdir "$HOME/Wallpapers" 2>/dev/null || warn "~/Wallpapers not empty — leaving it alone."
fi
mkdir -p "$HOME/Wallpapers"
find "$HOME/Wallpapers" -maxdepth 1 -type l -delete
ln -sf "$HOME/Pictures/wallpapers/collections/elden-ring/"* "$HOME/Wallpapers/" 2>/dev/null || true

# Pre-render the theme files (colors.toml, hyprlock/kitty/alacritty colors)
# so nothing references a missing file before the first Super+T apply.
if [[ -s $default_wall ]]; then
  info "Pre-rendering the default theme's color files..."
  aether --generate "$default_wall" --no-apply >/dev/null 2>&1 \
    || warn "Could not pre-render theme files — press Super+T after login to apply a theme."
fi

"$HOME/.local/bin/waybar-theme-icons" >/dev/null 2>&1 || true

# fastfetch in new terminals
if ! grep -q "fastfetch" "$HOME/.bashrc" 2>/dev/null; then
  cat "$REPO/extras/bashrc-snippet.sh" >> "$HOME/.bashrc"
  info "Added fastfetch snippet to ~/.bashrc"
fi

echo
info "${BLD}Done!${RST} Log into a Hyprland session and:"
echo "    Super+T           switch theme (elden-ring, cyberpunk-2077, god-of-war, ...)"
echo "    Super+Left/Right  cycle wallpapers within the current theme"
echo "    Super+Return      terminal (alacritty)   Super+Space  launcher (walker)"
echo
echo "  First theme apply happens inside Hyprland: press Super+T and pick one."
[[ -d $BACKUP ]] && echo "  Your previous configs are in: $BACKUP"
