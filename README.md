# CachyOS configuration

Hyprland (`hyprland.conf`), Waybar, Fish, Helium, mpv, and SearXNG.

Install on a CachyOS machine as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/Cayeden/config/main/setup.sh | bash
```

Review `install.sh` before running it: it upgrades packages, installs applications and configs, connects WARP, and enables Docker, Bluetooth, and UFW. It does not uninstall existing applications or modify storage mounts. Replaced desktop and shell configuration files are backed up under `~/.local/state/config-backups/`.

## Local settings

The public configs use automatic monitor placement, the root filesystem for the disk widget, and standard SSH key filenames. Adjust those settings locally for your machine. Add personal SSH identities through your private SSH configuration or `ssh-add`; do not commit private keys or credentials. Wallpaper is stored at `~/.local/share/wallpapers/default.jpg`.

## Helium updates

Each install checks the latest official Helium release. You can also run:

```bash
~/.local/bin/update-helium
```

The updater checks the release SHA-256 digest, skips an identical installed binary, and replaces the executable only after a verified download. Downloads are cached under `~/.cache/helium-updater/`. Updating `/usr/local/bin/helium` requires sudo; reopen Helium afterward. Desktop defaults and the Fish, Hyprland, and UWSM browser environment point to Helium.

## CPU temperature

The Waybar widget discovers `k10temp`, `zenpower`, or `coretemp` sensors by driver and label instead of a fixed hwmon number. System setup loads `k10temp` persistently on AMD machines. If no CPU temperature sensor is available, CPU utilization remains visible and the tooltip explains the missing temperature.
