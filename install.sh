#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
echo "✓ Hyprland config installed"

# Update Packages and Package DataBase
sudo pacman -Syu --noconfirm >/dev/null 2>&1
echo "✓ Packages updated"

# Install User Packages
sudo pacman -S --noconfirm keepassxc steam grim slurp wl-clipboard feh vlc hyprpaper >/dev/null 2>&1
echo "✓ Packages installed (pacman)"
paru -S --noconfirm visual-studio-code-bin >/dev/null 2>&1
echo "✓ Packages installed (paru/AUR)"

# Browser
if [ ! -f /usr/local/bin/helium ]; then
  pkill -f "/tmp/.mount_helium" 2>/dev/null || true
  latest_url=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest \
    | grep -m1 "browser_download_url.*x86_64.AppImage" \
    | cut -d '"' -f 4)
  sudo curl -L -o /usr/local/bin/helium "$latest_url" >/dev/null 2>&1
  sudo chmod +x /usr/local/bin/helium

  browser_export="set -gx BROWSER /usr/local/bin/helium"
  fish_config="$HOME/.config/fish/config.fish"
  mkdir -p "$(dirname "$fish_config")"
  touch "$fish_config"
  grep -Fxq "$browser_export" "$fish_config" || echo "$browser_export" >> "$fish_config"

  cp desktop-files/helium.desktop "$HOME/.local/share/applications/" 2>/dev/null || true
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  xdg-mime default helium.desktop x-scheme-handler/http 2>/dev/null || true
  xdg-mime default helium.desktop x-scheme-handler/https 2>/dev/null || true
  echo "✓ Helium Browser installed"
fi

# Storage mount

STORAGE_UUID="3a0db3a3-f6ab-4ce6-8c18-1e27e54ce7ef"
STORAGE_MNT="/mnt/storage"

# Do not run as root
if [ "$(id -u)" -eq 0 ]; then
  echo "✗ Do not run this script as root"
  exit 1
fi

# Create mountpoint
sudo mkdir -p "$STORAGE_MNT"

# Add to fstab if missing
if ! sudo grep -q "$STORAGE_UUID" /etc/fstab; then
  echo "UUID=$STORAGE_UUID $STORAGE_MNT btrfs defaults,noatime,compress=zstd 0 0" \
    | sudo tee -a /etc/fstab >/dev/null
  echo "✓ Added /mnt/storage to /etc/fstab"
fi

# Mount via fstab
sudo mount "$STORAGE_MNT"

# Hard safety check
if ! mountpoint -q "$STORAGE_MNT"; then
  echo "✗ Failed to mount $STORAGE_MNT"
  exit 1
fi

# Resolve user dynamically
USER_UID="$(id -u)"
USER_GID="$(id -g)"

# Never recursive
sudo chown "$USER_UID:$USER_GID" "$STORAGE_MNT"

echo "✓ /mnt/storage mounted and ownership set"

# Downloading wallpaper
if [ ! -f /mnt/storage/wallpaper.png ]; then
  curl -L -o /mnt/storage/wallpaper.png "https://w.wallhaven.cc/full/qz/wallhaven-qzvw3r.jpg" >/dev/null 2>&1
  echo "✓ Wallpaper downloaded"
fi

# Set max volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1