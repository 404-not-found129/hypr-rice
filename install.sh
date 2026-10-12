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

REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------- checks ----
[[ -f /etc/arch-release ]] || die "This installer targets Arch Linux (pacman)."
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root (sudo is used where needed)."
command -v sudo >/dev/null || die "sudo is required."

# ------------------------------------------------------------- bootstrap ----
# Piped from curl there is no checkout next to the script: clone (or update)
# one and re-run from it, with the terminal as stdin so prompts still work.
if [[ ! -f $REPO/lib/common.sh ]]; then
  SRC="$HOME/.local/share/hypr-rice"
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  if [[ -d $SRC/.git ]]; then
    info "Updating hypr-rice in $SRC..."
    git -C "$SRC" pull --ff-only
  else
    info "Cloning hypr-rice into $SRC..."
    git clone --depth 1 https://github.com/404-not-found129/hypr-rice.git "$SRC"
  fi
  exec bash "$SRC/install.sh" "$@" </dev/tty
fi

# shellcheck source=lib/common.sh
source "$REPO/lib/common.sh"

if command -v omarchy >/dev/null; then
  warn "Omarchy detected. This full install REPLACES Omarchy's Hyprland config"
  warn "(keybinds, bar, launcher) with the rice's own. To keep Omarchy and just"
  warn "add the themes, run install-omarchy.sh instead."
  read -rp "Replace Omarchy's desktop config anyway? [y/N] " a; [[ ${a,,} == y* ]] || exit 0
fi

info "This will install packages and place configs for: Hyprland (Lua config),"
info "waybar, alacritty/kitty, Aether theming, theme switcher and wallpaper cycling."
read -rp "Continue? [y/N] " a; [[ ${a,,} == y* ]] || exit 0

# ---------------------------------------------------------- dependencies ----
PACMAN_DEPS=(
  hyprland hyprlock hypridle hyprpicker hyprshot xdg-desktop-portal-hyprland
  hyprpolkitagent waybar alacritty kitty awww grim swaync
  network-manager-applet thunar pavucontrol pamixer wl-clipboard
  papirus-icon-theme breeze-cursors xorg-xcursorgen ttf-jetbrains-mono-nerd
  fastfetch eza btop imagemagick curl python python-gobject gtk4 acl polkit
  rofi-wayland git base-devel ffmpeg file
)
AUR_DEPS=(
  aether walker-bin wlogout
  elephant-bin elephant-desktopapplications-bin elephant-runner-bin
  elephant-calc-bin elephant-clipboard-bin elephant-files-bin
  elephant-menus-bin elephant-providerlist-bin elephant-symbols-bin
  elephant-websearch-bin mpvpaper
)

mapfile -t need < <(missing "${PACMAN_DEPS[@]}")
if ((${#need[@]})); then
  info "Installing official packages (pacman)..."
  sudo pacman -S --needed --noconfirm "${need[@]}"
fi

ensure_aur_helper
mapfile -t need < <(missing "${AUR_DEPS[@]}")
if ((${#need[@]})); then
  info "Installing AUR packages ($aur_helper)..."
  "$aur_helper" -S --needed --noconfirm "${need[@]}"
fi

# ------------------------------------------------------------- configs ------
backup() { # backup <path>
  if [[ -e $1 && ! -L $1 ]]; then
    mkdir -p "$BACKUP"
    mv "$1" "$BACKUP/$(basename "$1").$(date +%s)"
    warn "Existing $(basename "$1") moved to $BACKUP"
  fi
}

info "Installing configs (existing ones are backed up to $BACKUP)..."
for d in hypr waybar alacritty kitty swaync walker fastfetch wlogout; do
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
chmod +x "$HOME/.local/bin/"{wallcycle,themeswitch,papirus-accent,waybar-theme-icons,live-wallpaper} \
         "$HOME/.config/aether/custom/hypr-wallpaper/post-apply.sh"

mkdir -p "$HOME/.config/systemd/user"
cp -r "$REPO/systemd/." "$HOME/.config/systemd/user/"
systemctl --user daemon-reload 2>/dev/null || true

# Point every placeholder at this user's home
grep -rlZ "__HOME__" "$HOME/.config/hypr" "$HOME/.config/waybar" \
  "$HOME/.config/aether" 2>/dev/null | xargs -0 -r sed -i "s|__HOME__|$HOME|g"

install_papirus_folders

install_wallpapers
install_live_wallpapers

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

# Pre-build the themed cursor set for every theme so switching never waits
# on first-time generation (each set is recolored Breeze, ~1s per theme).
info "Pre-building themed cursor sets..."
for bp in "$HOME/.config/aether/blueprints/"*.json; do
  t=$(basename "$bp" .json)
  python3 "$HOME/.local/bin/game-cursors" --build "$t" >/dev/null 2>&1 \
    || warn "cursor set for $t failed to build (will retry on first switch)"
done

# eza (ls) colors for the default theme, so the first shell has them
python3 "$HOME/.local/bin/eza-theme" >/dev/null 2>&1 || true

# eza aliases + fastfetch in new terminals
if ! grep -q "eza (modern ls)" "$HOME/.bashrc" 2>/dev/null; then
  cat "$REPO/extras/bashrc-snippet.sh" >> "$HOME/.bashrc"
  info "Added eza/fastfetch snippet to ~/.bashrc"
fi

echo
info "${BLD}Done!${RST} Log into a Hyprland session and:"
echo "    Super+T           switch theme (elden-ring, cyberpunk-2077, god-of-war, ...)"
echo "    Super+Left/Right  cycle wallpapers within the current theme"
echo "    Super+Return      terminal (alacritty)   Super+Space  launcher (walker)"
echo
echo "  First theme apply happens inside Hyprland: press Super+T and pick one."
[[ -d $BACKUP ]] && echo "  Your previous configs are in: $BACKUP"
