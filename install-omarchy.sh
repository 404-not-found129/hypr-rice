#!/usr/bin/env bash
#
# hypr-rice for Omarchy — adds the game themes to Omarchy's own theme system.
# Leaves Omarchy's Hyprland config, keybinds, bar, launcher and terminals alone.
# Safe to re-run.
#
set -Eeuo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLD=$'\e[1m'; RST=$'\e[0m'
info()  { printf '%s[*]%s %s\n' "$GRN" "$RST" "$*"; }
warn()  { printf '%s[!]%s %s\n' "$YLW" "$RST" "$*"; }
die()   { printf '%s[x]%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }
trap 'die "Install failed at line $LINENO. Fix the issue and re-run — the script is idempotent."' ERR

REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"

# ---------------------------------------------------------------- checks ----
[[ -f /etc/arch-release ]] || die "This installer targets Arch Linux (pacman)."
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root (sudo is used where needed)."
command -v sudo >/dev/null || die "sudo is required."
command -v omarchy >/dev/null || die "Omarchy not found. For a plain Arch + Hyprland setup, use install.sh."

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
  exec bash "$SRC/install-omarchy.sh" "$@" </dev/tty
fi

# shellcheck source=lib/common.sh
source "$REPO/lib/common.sh"

info "This adds the hypr-rice game themes to Omarchy's theme menu, with themed"
info "app icons, cursors, folder colors and animated wallpapers. Your keybinds, bar"
info "and Hyprland config are not touched."
read -rp "Continue? [y/N] " a; [[ ${a,,} == y* ]] || exit 0

# ---------------------------------------------------------- dependencies ----
DEPS=(
  papirus-icon-theme breeze-cursors xorg-xcursorgen librsvg imagemagick
  python acl curl ffmpeg inotify-tools file
)
AUR_DEPS=(mpvpaper)
mapfile -t need < <(missing "${DEPS[@]}")
if ((${#need[@]})); then
  info "Installing packages (pacman)..."
  sudo pacman -S --needed --noconfirm "${need[@]}"
fi
mapfile -t need < <(missing "${AUR_DEPS[@]}")
if ((${#need[@]})); then
  ensure_aur_helper
  info "Installing AUR packages ($aur_helper)..."
  "$aur_helper" -S --needed --noconfirm "${need[@]}"
fi

# --------------------------------------------------------------- scripts ----
info "Installing theme scripts to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
for s in game-icons game-cursors papirus-accent eza-theme live-wallpaper; do
  install -m755 "$REPO/bin/$s" "$HOME/.local/bin/$s"
done

install_papirus_folders
install_wallpapers
install_live_wallpapers

# ---------------------------------------------------------------- themes ----
# A theme with videos gets them as its wallpapers (live-wallpaper posters
# copies their posters into ~/.config/omarchy/backgrounds/<theme>/); one
# without falls back to its still collection.
has_videos() { compgen -G "$HOME/Pictures/wallpapers/live/$1/*.mp4" >/dev/null; }
stills="$HOME/Pictures/wallpapers/collections"

info "Adding themes to ~/.config/omarchy/themes..."
for dir in "$REPO/omarchy/themes/"*/; do
  t=$(basename "$dir")
  dest="$HOME/.config/omarchy/themes/$t"
  mkdir -p "$dest"
  cp "$dir/colors.toml" "$dest/colors.toml"
  if ! has_videos "$t" && [[ -L $dest/backgrounds || ! -e $dest/backgrounds ]]; then
    ln -sfn "$stills/$t" "$dest/backgrounds"
  fi
  printf '  %s%s\n' "$t" "$(has_videos "$t" && echo " (animated)")"
done

# Omarchy already ships these themes: keep its colors, add the rice's wallpapers
for t in gruvbox tokyo-night; do
  bg="$HOME/.config/omarchy/backgrounds/$t"
  if ! has_videos "$t" && [[ -L $bg || ! -e $bg ]]; then
    mkdir -p "$(dirname "$bg")"
    ln -sfn "$stills/$t" "$bg"
  fi
  printf '  %s (Omarchy colors, rice wallpapers%s)\n' "$t" "$(has_videos "$t" && echo ", animated")"
done
"$HOME/.local/bin/live-wallpaper" posters

# ------------------------------------------------------------------ hook ----
# Remember Omarchy's cursor so the hook can restore it on non-rice themes
state="$HOME/.local/state/hypr-rice"
if [[ ! -f $state/cursor-theme ]]; then
  mkdir -p "$state"
  cursor=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
  [[ -z $cursor || $cursor == Aether-* ]] && cursor=default
  printf '%s\n' "$cursor" > "$state/cursor-theme"
fi

omarchy hook install theme-set "$REPO/omarchy/hypr-rice.sh" >/dev/null
omarchy hook install post-boot "$REPO/omarchy/post-boot/hypr-rice.sh" >/dev/null
info "Installed theme-set and post-boot hooks (~/.config/omarchy/hooks/*.d/hypr-rice.sh)"

info "Pre-building themed cursor sets..."
for dir in "$REPO/omarchy/themes/"*/; do
  t=$(basename "$dir")
  python3 "$HOME/.local/bin/game-cursors" --build "$t" >/dev/null 2>&1 \
    || warn "cursor set for $t failed to build (will retry on first switch)"
done

# ls colors that follow the theme (Omarchy already aliases ls to eza)
if ! grep -q "eza/colors.sh" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# hypr-rice: eza colors follow the Omarchy theme\n[[ -f ~/.config/eza/colors.sh ]] && source ~/.config/eza/colors.sh\n' >> "$HOME/.bashrc"
  info "Added eza theme colors to ~/.bashrc"
fi

# Follow the background from now on (the post-boot hook does this at login)
pkill -f "live-wallpaper watch" 2>/dev/null || true
setsid "$HOME/.local/bin/live-wallpaper" watch >/dev/null 2>&1 </dev/null &

echo
info "${BLD}Done!${RST} Pick a theme from Omarchy's theme menu (Super+Ctrl+Shift+Space),"
echo "  or run:  omarchy theme set elden-ring"
echo
echo "  Rice themes: elden-ring, ashen-flame, god-of-war, fallout, cyberpunk-2077,"
echo "  catppuccin-mocha, plus extra wallpapers for Omarchy's gruvbox and tokyo-night."
echo
echo "  Animated wallpapers: switch between a theme's videos with Omarchy's background"
echo "  switcher (Super+Ctrl+Space). Skipped the download? Run: live-wallpaper fetch"
