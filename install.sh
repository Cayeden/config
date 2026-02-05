#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"

# Update Packages and Package DataBase
echo "Updating Package DataBase & Packages"
sudo pacman -Syu --noconfirm

# Install User Packages
echo "Installing User Packages"
sudo pacman -S --noconfirm keepassxc steam grim slurp wl-clipboard feh vlc hyprpaper

paru -S --noconfirm visual-studio-code-bin

# Browser
echo "Installing Helium Browser"

# Make sure no browser is running
pkill -f "/tmp/.mount_helium" 2>/dev/null || true

# Find latest release AppImage file
latest_url=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest \
  | grep -m1 "browser_download_url.*x86_64.AppImage" \
  | cut -d '"' -f 4)

# Download helium and make it executable
sudo curl -L -o /usr/local/bin/helium "$latest_url"
sudo chmod +x /usr/local/bin/helium

browser_export="set -gx BROWSER /usr/local/bin/helium"
fish_config="$HOME/.config/fish/config.fish"

# Ensure fish config file exists
mkdir -p "$(dirname "$fish_config")"
touch "$fish_config"

# Add browser export if not available
grep -Fxq "$browser_export" "$fish_config" || echo "$browser_export" >> "$fish_config"

# Ensure the desktop file is in the right place
cp desktop-files/helium.desktop "$HOME/.local/share/applications/"

# Update the desktop database
update-desktop-database "$HOME/.local/share/applications"

# Set Helium as default for http/https schemes
xdg-mime default helium.desktop x-scheme-handler/http
xdg-mime default helium.desktop x-scheme-handler/https

echo "Done Installing Helium Browser"

# Setup /mnt/storage
sudo mkdir -p /mnt/storage
if ! mountpoint -q /mnt/storage; then
  sudo mount /mnt/storage 2>/dev/null || sudo btrfs device scan && sudo mount -U "$(sudo btrfs filesystem show 2>/dev/null | grep -oP 'uuid: \K[a-f0-9-]+' | head -1)" /mnt/storage
  echo "Mounted /mnt/storage"
fi

if mountpoint -q /mnt/storage; then
  sudo grep -q '/mnt/storage' /etc/fstab || echo "UUID=$(sudo btrfs filesystem show /mnt/storage | grep -oP 'uuid: \K[a-f0-9-]+' | head -1) /mnt/storage btrfs defaults,noatime,compress=zstd 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo chown -R "$USER:$USER" /mnt/storage
  echo "Configured /mnt/storage in /etc/fstab and set ownership to $USER"
fi

# Downloading wallpaper
curl -L -o /mnt/storage/wallpaper.png "https://w.wallhaven.cc/full/qz/wallhaven-qzvw3r.jpg"
