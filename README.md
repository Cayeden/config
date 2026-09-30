# CachyOS configuration

Hyprland (`hyprland.conf`), Waybar, Fish, Helium, mpv, and SearXNG.

Install on a CachyOS machine as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/Cayeden/config/main/setup.sh | bash
```

The full installer upgrades packages and provisions the services and storage mount in `install.sh`. Review that file before running it on another machine.

For an existing installation, clone this repo and run the scoped refresh:

```bash
./scripts/refresh-local.sh
```

This removes the user installations of OpenCode, Claude Code, mouse recorder, and Fan Comfort Tuner, and archives their files under `~/.local/state/config-backups/`. It installs Polkit and mpv, configures Helium as the browser, and updates the CPU widget. It leaves SearXNG, WARP, Docker, storage mounts, and existing LACT GPU settings untouched.

## Helium updates

Each install/refresh checks the latest official Helium release. You can also run:

```bash
~/.local/bin/update-helium
```

The updater checks the release SHA-256 digest, skips an identical installed binary, and replaces the executable only after a verified download. Downloads are cached under `~/.cache/helium-updater/`. Updating `/usr/local/bin/helium` requires sudo; reopen Helium afterward. Desktop defaults and the Fish, Hyprland, and UWSM browser environment point to Helium.

## CPU temperature

The Waybar widget discovers `k10temp`, `zenpower`, or `coretemp` sensors by driver and label instead of a fixed hwmon number. The system setup loads `k10temp` persistently on AMD machines. If no CPU temperature sensor is available, CPU utilization remains visible and the tooltip explains the missing temperature.
