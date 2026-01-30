#!/usr/bin/env bash

set -e

# Browser
echo Installing Helium Browser
latest_url=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest \
  | grep "browser_download_url.*x86_64.AppImage\"" \
  | cut -d '"' -f 4)

sudo curl -L -o /usr/local/bin/Helium "$latest_url"
sudo chmod +x /usr/local/bin/Helium
echo Done Installing Helium Browser
