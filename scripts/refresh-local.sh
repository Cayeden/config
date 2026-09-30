#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this as your normal user; sudo will request your password." >&2
  exit 1
fi
sudo -v
sudo pacman -S --needed --noconfirm polkit-kde-agent mpv lact python-gobject gtk4 libadwaita curl jq fish desktop-file-utils
./scripts/configure-user.sh
./scripts/configure-system.sh
./scripts/update-helium
hyprctl reload
echo "Local refresh complete."
