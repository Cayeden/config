#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
[[ "$(id -u)" -ne 0 ]] || { echo "Run as your normal user." >&2; exit 1; }
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
backup=""
copy_config() {
    local source=$1 destination=$2
    if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then return; fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ -z "$backup" ]]; then
            mkdir -p "$state_home/config-backups"
            backup=$(mktemp -d "$state_home/config-backups/noctalia-XXXXXXXX")
            chmod 700 "$backup"
        fi
        mkdir -p "$backup/$(dirname "${destination#/}")"
        cp -a "$destination" "$backup/${destination#/}"
    fi
    mkdir -p "$(dirname "$destination")"
    cp --remove-destination "$source" "$destination"
}
copy_config hypr/hyprland.lua "$config_home/hypr/hyprland.lua"
for script in noctalia/scripts/*; do
    copy_config "$script" "$config_home/noctalia/scripts/${script##*/}"
    chmod +x "$config_home/noctalia/scripts/${script##*/}"
done
for script in noctalia/plugins/local-services/*; do
    copy_config "$script" "$data_home/noctalia/plugins/local-services/${script##*/}"
done
copy_config noctalia/config.toml "$config_home/noctalia/config.toml"
mkdir -p "$HOME/Pictures/Wallpapers"
if [[ -f /mnt/storage/wallpaper.png && ! -e "$HOME/Pictures/Wallpapers/wallpaper.png" && ! -L "$HOME/Pictures/Wallpapers/wallpaper.png" ]]; then
    ln -s /mnt/storage/wallpaper.png "$HOME/Pictures/Wallpapers/wallpaper.png"
fi
mkdir -p "$HOME/.local/bin"
copy_config scripts/stratactl "$HOME/.local/bin/stratactl"
chmod +x "$HOME/.local/bin/stratactl"
copy_config scripts/opencode-local "$HOME/.local/bin/opencode-local"
chmod +x "$HOME/.local/bin/opencode-local"
if [[ -x "$data_home/opencode-desktop/OpenCode.AppImage" ]]; then
    desktop=$(mktemp)
    cat > "$desktop" <<EOF
[Desktop Entry]
Name=OpenCode
Comment=OpenCode Desktop with local Strata
Exec="$HOME/.local/bin/opencode-local" %U
Terminal=false
Type=Application
Icon=ai.opencode.desktop
StartupWMClass=ai.opencode.desktop
Categories=Development;
MimeType=x-scheme-handler/opencode;
EOF
    copy_config "$desktop" "$data_home/applications/ai.opencode.desktop.desktop"
    rm -f "$desktop"
    update-desktop-database "$data_home/applications"
fi
if command -v noctalia >/dev/null; then noctalia config validate; fi
printf 'Noctalia configuration installed. Backups: %s\n' "${backup:-none needed}"
printf 'Existing Noctalia GUI overrides remain in %s/noctalia/settings.toml.\n' "$state_home"
