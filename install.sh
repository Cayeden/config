#!/usr/bin/env bash

set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this installer as your normal user." >&2
  exit 1
fi
cd "$(dirname "$(readlink -f "$0")")"

# Update Packages and Package DataBase
sudo pacman -Syu --noconfirm
echo "✓ Packages updated"

# Install User Packages
sudo pacman -S --needed --noconfirm keepassxc steam python grim slurp satty ddcutil wl-clipboard mpv noctalia obs-studio pavucontrol ripgrep cloudflare-warp-bin btop networkmanager jq docker docker-compose github-cli ufw bluez bluez-utils paru kitty dolphin fish playerctl brightnessctl curl openssl desktop-file-utils
echo "✓ Packages installed (pacman)"
paru -S --needed --noconfirm visual-studio-code-bin lmstudio-bin
echo "✓ Packages installed (paru/AUR)"

# Desktop and shell configuration
./scripts/configure-user.sh
echo "✓ Hyprland, Fish, and Noctalia configuration installed"

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

# Polkit and CPU sensor driver
./scripts/configure-system.sh

# Browser: check the latest release on every install, including existing installs.
./scripts/update-helium

# Storage mount

STORAGE_UUID="3a0db3a3-f6ab-4ce6-8c18-1e27e54ce7ef"
STORAGE_MNT="/mnt/storage"

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