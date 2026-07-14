#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
cp hypr/hyprlock.conf "$HOME/.config/hypr/hyprlock.conf"
echo "✓ Hyprland config installed"

# Fish Config
mkdir -p "$HOME/.config/fish"
cp fish/config.fish "$HOME/.config/fish/config.fish"
echo "✓ Fish config installed"

# Waybar Config
mkdir -p "$HOME/.config/waybar/scripts"
cp waybar/config.jsonc "$HOME/.config/waybar/config.jsonc"
cp waybar/style.css "$HOME/.config/waybar/style.css"
cp waybar/scripts/*.sh "$HOME/.config/waybar/scripts/"
chmod +x "$HOME/.config/waybar/scripts/"*.sh
echo "✓ Waybar config installed"

# Update Packages and Package DataBase
sudo pacman -Syu --noconfirm >/dev/null 2>&1
echo "✓ Packages updated"

# Install User Packages
sudo pacman -S --noconfirm keepassxc steam grim slurp wl-clipboard vlc hyprpaper obs-studio pavucontrol ripgrep cloudflare-warp-bin waybar hyprlock btop networkmanager jq docker docker-compose github-cli ufw bluez bluez-utils >/dev/null 2>&1
echo "✓ Packages installed (pacman)"
paru -S --noconfirm visual-studio-code-bin lmstudio-bin >/dev/null 2>&1
echo "✓ Packages installed (paru/AUR)"

# VPN (Cloudflare WARP)
sudo systemctl enable --now warp-svc >/dev/null 2>&1
warp-cli registration show >/dev/null 2>&1 || warp-cli --accept-tos registration new >/dev/null 2>&1
warp-cli --accept-tos mode warp >/dev/null 2>&1
warp-cli --accept-tos connect >/dev/null 2>&1
echo "✓ Cloudflare WARP connected"

# Docker (enable daemon + let this user run docker without sudo via the docker group)
sudo systemctl enable --now docker.service >/dev/null 2>&1
sudo usermod -aG docker "$USER"
echo "✓ Docker enabled (log out/in for 'docker' group to take effect)"

# Bluetooth
sudo systemctl enable --now bluetooth.service >/dev/null 2>&1
echo "✓ Bluetooth enabled"

# Firewall (UFW)
sudo systemctl enable --now ufw.service >/dev/null 2>&1
sudo ufw --force enable >/dev/null 2>&1
echo "✓ UFW firewall enabled"

# SearXNG (local metasearch on :8888, used as LM Studio's search backend)
mkdir -p "$HOME/searxng/core-config"
cp searxng/docker-compose.yml "$HOME/searxng/docker-compose.yml"
cp searxng/.env "$HOME/searxng/.env"
cp searxng/core-config/settings.yml "$HOME/searxng/core-config/settings.yml"
# inject a fresh secret_key (the real one is never stored in this public repo)
sed -i "s/SEARXNG_SECRET_PLACEHOLDER/$(openssl rand -hex 32)/" "$HOME/searxng/core-config/settings.yml"
sudo docker compose -f "$HOME/searxng/docker-compose.yml" up -d >/dev/null 2>&1
echo "✓ SearXNG running on http://127.0.0.1:8888"

# Browser
if [ ! -f /usr/local/bin/helium ]; then
  pkill -f "/tmp/.mount_helium" 2>/dev/null || true
  latest_url=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest \
    | grep -m1 "browser_download_url.*x86_64.AppImage" \
    | cut -d '"' -f 4)
  sudo curl -L -o /usr/local/bin/helium "$latest_url" >/dev/null 2>&1
  sudo chmod +x /usr/local/bin/helium

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

# Mount via fstab if not already mounted
if ! mountpoint -q "$STORAGE_MNT"; then
  sudo mount "$STORAGE_MNT"
  if ! mountpoint -q "$STORAGE_MNT"; then
    echo "✗ Failed to mount $STORAGE_MNT"
    exit 1
  fi
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