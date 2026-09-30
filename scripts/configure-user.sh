#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your normal user." >&2; exit 1; }

state=${XDG_STATE_HOME:-$HOME/.local/state}
mkdir -p "$state/config-backups"
backup=$(mktemp -d "$state/config-backups/refresh-XXXXXXXX")
chmod 700 "$backup"

archive() {
  local source=$1 relative=${1#"$HOME/"}
  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$backup/$(dirname "$relative")"
    mv "$source" "$backup/$relative"
  fi
}

copy_config() {
  local source=$1 destination=$2
  if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then return; fi
  archive "$destination"
  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination"
}

copy_config fish/config.fish "$HOME/.config/fish/config.fish"
copy_config hypr/hyprland.lua "$HOME/.config/hypr/hyprland.lua"
copy_config hypr/hyprlock.conf "$HOME/.config/hypr/hyprlock.conf"
copy_config waybar/config.jsonc "$HOME/.config/waybar/config.jsonc"
copy_config waybar/style.css "$HOME/.config/waybar/style.css"
for script in waybar/scripts/*.sh; do
  copy_config "$script" "$HOME/.config/waybar/scripts/${script##*/}"
  chmod +x "$HOME/.config/waybar/scripts/${script##*/}"
done

mkdir -p "$HOME/.config/uwsm"
environment_file="$HOME/.config/uwsm/env"
if [[ -f "$environment_file" ]]; then
  cp "$environment_file" "$backup/uwsm-env"
  sed -i '/^[[:space:]]*\(export[[:space:]]\+\)\?BROWSER=/d' "$environment_file"
fi
printf '\nexport BROWSER=/usr/local/bin/helium\n' >> "$environment_file"
systemctl --user set-environment BROWSER=/usr/local/bin/helium

copy_config scripts/update-helium "$HOME/.local/bin/update-helium"
chmod +x "$HOME/.local/bin/update-helium"

mkdir -p "$HOME/.local/share/applications"
copy_config desktop-files/helium.desktop "$HOME/.local/share/applications/helium.desktop"
update-desktop-database "$HOME/.local/share/applications"
for type in x-scheme-handler/http x-scheme-handler/https text/html; do
  xdg-mime default helium.desktop "$type"
done
for type in video/mp4 video/x-matroska video/webm video/x-msvideo audio/mpeg audio/flac audio/ogg; do
  xdg-mime default mpv.desktop "$type"
done
echo "User configuration updated. Previous files are archived in $backup"
