#!/usr/bin/env bash

set -e

# Hyprland Config
mkdir -p "$HOME/.config/hypr" "$HOME/.local/share/applications"
cp hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"

# Update Packages and Package DataBase
echo "Updating Package DataBase & Packages"
sudo pacman -Syu

# Install User packages
echo "Installing VS Code and KeePassXC"
sudo pacman -S --noconfirm code keepassxc

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

# SSH Agent Setup
grep -Fq 'SSH Agent Auto-Start' "$fish_config" || cat <<'EOF' >> "$fish_config"
# --- SSH Agent Auto-Start (Persistent) ---
set SSH_AGENT_ENV $HOME/.ssh/agent.fish

function agent_load_env
    if test -f $SSH_AGENT_ENV
        source $SSH_AGENT_ENV
    end
end

function agent_start
    umask 077
    # Use bash to start agent and convert to Fish syntax safely
    bash -c "ssh-agent -c | sed \"s/^export /set -gx /; s/= / /; s/;\$//\" > \\\"$SSH_AGENT_ENV\\\""
    source $SSH_AGENT_ENV
    ssh-add
end

agent_load_env

ssh-add -l >/dev/null 2>&1
set agent_run_state $status

if test -z "$SSH_AUTH_SOCK" -o $agent_run_state -eq 2
    agent_start
else if test -n "$SSH_AUTH_SOCK" -a $agent_run_state -eq 1
    ssh-add
end
EOF
