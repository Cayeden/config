#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"

# Update Packages and Package DataBase
echo "Updating Package DataBase & Packages"
sudo pacman -Syu

# Install User packages
echo "Installing User Packages"
sudo pacman -S --noconfirm code keepassxc steam

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

# -------------------------
# SSH Agent Setup via systemd service
# -------------------------
echo "Setting up SSH Agent systemd service..."

# Copy pre-made systemd service
mkdir -p "$HOME/.config/systemd/user"
cp services/ssh-agent.service "$HOME/.config/systemd/user/ssh-agent.service"

# Enable and start the service
systemctl --user daemon-reload
systemctl --user enable ssh-agent.service
systemctl --user start ssh-agent.service

# Ensure Fish reads SSH_AUTH_SOCK from systemd
ssh_sock_export='set -gx SSH_AUTH_SOCK (systemctl show --user ssh-agent.service --property=Environment | string match -r "SSH_AUTH_SOCK=.*" | string replace -r "SSH_AUTH_SOCK=" "")'
grep -Fxq "$ssh_sock_export" "$fish_config" || echo "$ssh_sock_export" >> "$fish_config"
systemctl --user import-environment SSH_AUTH_SOCK

mkdir -p "$HOME/.config/hypr"
cp hypr/autostart "$HOME/.config/hypr/autostart"
chmod +x "$HOME/.config/hypr/autostart"

echo "Done setting up SSH Agnet systemd service"