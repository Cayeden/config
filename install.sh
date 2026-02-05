#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
cp hypr/hyprpaper.conf "$HOME/.config/hypr/hyprpaper.conf"

# Update Packages and Package DataBase
echo "Updating Package DataBase & Packages"
sudo pacman -Syu --noconfirm

# Install User Packages
echo "Installing User Packages"
sudo pacman -S --noconfirm keepassxc steam grim slurp wl-clipboard feh vlc hyprpaper

paru -S --noconfirm visual-studio-code-bin

# Downloading wallpaper
curl -L -o /mnt/storage/wallpaper.png "https://w.wallhaven.cc/full/qz/wallhaven-qzvw3r.jpg"

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
