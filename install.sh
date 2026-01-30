#!/usr/bin/env bash

set -e

# Update Packages and Package DataBase
sudo pacman -Syu

# Install VS Code
sudo pacman -S --noconfirm code

# Install KeePassXC
sudo pacman -S keepassxc

# Browser
echo Installing Helium Browser

pkill -f "/tmp/.mount_Helium"

latest_url=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest \
  | grep "browser_download_url.*x86_64.AppImage\"" \
  | cut -d '"' -f 4)

sudo curl -L -o /usr/local/bin/Helium "$latest_url"
sudo chmod +x /usr/local/bin/Helium
echo Done Installing Helium Browser
