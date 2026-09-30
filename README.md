# CachyOS configuration

Hyprland (`hyprland.conf`), Waybar, Fish, Helium, mpv, and SearXNG.

Install on a CachyOS machine as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/Cayeden/config/main/setup.sh | bash
```

Review `install.sh` before running it: it upgrades packages, installs applications and configs, connects WARP, enables Docker, Bluetooth, and UFW, and configures the existing `/mnt/storage` mount. It does not uninstall existing applications. Replaced desktop and shell configuration files are backed up under `~/.local/state/config-backups/`.

## Helium updates

Each install checks the latest official Helium release. You can also run:

```bash
~/.local/bin/update-helium
```

The updater checks the release SHA-256 digest, skips an identical installed binary, and replaces the executable only after a verified download. Downloads are cached under `~/.cache/helium-updater/`. Updating `/usr/local/bin/helium` requires sudo; reopen Helium afterward. Desktop defaults and the Fish, Hyprland, and UWSM browser environment point to Helium.

## CPU temperature

The Waybar widget discovers `k10temp`, `zenpower`, or `coretemp` sensors by driver and label instead of a fixed hwmon number. System setup loads `k10temp` persistently on AMD machines. If no CPU temperature sensor is available, CPU utilization remains visible and the tooltip explains the missing temperature.
