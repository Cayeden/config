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

# Setup /mnt/storage
sudo mkdir -p /mnt/storage
if ! mountpoint -q /mnt/storage; then
  sudo mount /mnt/storage 2>/dev/null || sudo btrfs device scan && sudo mount -U "$(sudo btrfs filesystem show 2>/dev/null | grep -oP 'uuid: \K[a-f0-9-]+' | head -1)" /mnt/storage
  echo "✓ Mounted /mnt/storage"
fi

if mountpoint -q /mnt/storage; then
  sudo grep -q '/mnt/storage' /etc/fstab || echo "UUID=$(sudo btrfs filesystem show /mnt/storage | grep -oP 'uuid: \K[a-f0-9-]+' | head -1) /mnt/storage btrfs defaults,noatime,compress=zstd 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo chown -R "$USER:$USER" /mnt/storage
  echo "✓ Configured /mnt/storage in /etc/fstab"
fi

# Downloading wallpaper
if [ ! -f /mnt/storage/wallpaper.png ]; then
  curl -L -o /mnt/storage/wallpaper.png "https://w.wallhaven.cc/full/qz/wallhaven-qzvw3r.jpg" >/dev/null 2>&1
  echo "✓ Wallpaper downloaded"
fi
