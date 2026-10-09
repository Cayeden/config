# CachyOS configuration

Hyprland (`hyprland.lua`, version 0.55 or newer), Noctalia 5, Fish, Helium, mpv, and SearXNG.

Install on a CachyOS machine as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/Cayeden/config/main/setup.sh | bash
```

Review `install.sh` before running it: it upgrades packages, installs applications and configs, connects WARP, enables Docker, Bluetooth, and UFW, and configures the existing `/mnt/storage` mount. It does not uninstall existing applications. Replaced desktop and shell configuration files are backed up under `~/.local/state/config-backups/`.

## Hyprland

The native Lua config preserves the existing monitors, keybindings, animations, window rules, wallpaper, and desktop layout. Hyprland selects the Lua backend when starting a session; after installing it into an existing session, log out and back in once. Noctalia supplies the bar, launcher, wallpaper, notifications, lock screen, screenshots, and Polkit agent. Super+R opens its launcher, Super+L locks, and Super+Shift+S selects a screenshot region. Existing Waybar and Hyprlock files are retained as fallback files.

Validate before starting a session:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

See the [official Lua announcement](https://hypr.land/news/26_lua/) and [configuration documentation](https://wiki.hypr.land/Configuring/Start/).

## Helium updates

Each install checks the latest official Helium release. You can also run:

```bash
~/.local/bin/update-helium
```

The updater checks the release SHA-256 digest, skips an identical installed binary, and replaces the executable only after a verified download. Downloads are cached under `~/.cache/helium-updater/`. Updating `/usr/local/bin/helium` requires sudo; reopen Helium afterward. Desktop defaults and the Fish, Hyprland, and UWSM browser environment point to Helium.

## Desktop configuration

On an existing machine with Noctalia installed, apply only the desktop changes:

```bash
./scripts/configure-desktop.sh
```

The script backs up changed files and installs the local-services plugin. It preserves Noctalia's GUI overrides in `~/.local/state/noctalia/settings.toml`, which take precedence over the repo config. It does not kill running desktop processes or uninstall packages. Log out and in to switch the live session, or stop your old shell tools and start Noctalia manually after validating the configs.

The wallpaper picker browses `~/Pictures/Wallpapers`. The desktop setup creates this folder and links the existing `/mnt/storage/wallpaper.png` when available. Add more images there to use them in the picker or wallpaper rotation.

```bash
noctalia config validate
noctalia plugins lint ~/.local/share/noctalia/plugins/local-services
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

The bar has one VRAM indicator. Its tooltip shows CPU usage and temperature, GPU usage and temperature, then VRAM used/total in GiB; clicking it opens System details. VPN and Strata sit together on the left. The launcher remains on Super+R. NVIDIA monitoring uses NVML. Notification popups are limited to DP-2, the left monitor. Weather is disabled. The Calendar panel is hidden, and Home shortcuts are limited to notifications and power profile. External-monitor brightness uses opt-in DDC/CI through ddcutil. These identical MSI displays need explicit bus pins: DP-2 uses I2C bus 4, DP-3 uses bus 5. The left display was identified with a temporary brightness change; adapt these pins on another machine. The custom plugin keeps Docker container count and tooltips, RiseupVPN connection status and window activation, and the Strata model toggle. RiseupVPN status requires its real tunnel and helper process; install `riseup-vpn` separately when needed. A user-installed `riseup-vpn` wrapper on PATH is respected.

## Strata model toggle

Strata and its model are installed separately. The desktop installer does not download model weights or start the model. After Strata setup creates its launcher, register it:

```bash
stratactl configure /path/to/Strata/run-iq2_xs.sh
```

The default API address is `http://127.0.0.1:8081`. Use `--url` for another local port. Runtime paths are saved privately in `~/.config/strata/control.json`, outside this repository. The controller starts a transient user service with a separate log under `~/.local/state/strata/server.log`; no model is loaded at login.

Click the Strata bar widget to load or unload. It shows Off, Loading, On, or Stopping. Clicking during loading cancels it. Unloading stops the service's complete process group, releasing model VRAM and RAM. It interrupts any active model request. A second click while stopping waits for shutdown rather than starting another model instance. An occupied API port blocks startup, and the controller only stops its registered service.

Right-click opens logs. Command-line equivalents:

```bash
stratactl status
stratactl toggle
stratactl start --wait
stratactl stop --wait
stratactl logs
stratactl open
```

Run `./scripts/install-opencode-desktop.sh` to install OpenCode Desktop 1.18.35 for Linux x86_64 from its official release, verified against its SHA512 checksum. It installs an OpenCode application-menu entry and icons. `opencode-local` starts the registered model, waits until it is loaded, and opens the desktop app. Closing OpenCode leaves Strata available; use the Strata bar toggle to unload it. The desktop app uses existing OpenCode configuration and chats. Configure its OpenAI-compatible provider to the Strata API separately and keep the context limit aligned with Strata's `--max-context`. Desktop provisioning refreshes the launcher without downloading the app or model. The standalone npm CLI is optional.

## CPU temperature

Noctalia discovers standard hwmon CPU sensors. System setup loads `k10temp` persistently on AMD machines. If a sensor is missing, CPU utilization remains available. An installed `zenpower-dkms` package can blacklist `k10temp` even when its module is unavailable for the running kernel; check `modinfo zenpower`, `lsmod`, and `/usr/lib/modprobe.d/zenpower.conf` before changing the sensor driver.

## Verification

Run the controller integration checks in a session with a working user systemd manager:

```bash
python tests/test_stratactl.py
```

They use isolated temporary configuration and temporary services. They check concurrent startup, cancellation of the whole process group, retained failure status, and protection of an occupied port. They do not load model weights.

For the specific stale zenpower blacklist issue, run:

```bash
sudo ./scripts/repair-cpu-sensor.sh
```

The repair loads k10temp, configures boot-time loading, and shadows the vendor blacklist when zenpower has no module for the current kernel. It preserves any nonempty existing local override and leaves the zenpower package installed. This is a separate repair command; desktop provisioning does not run it.
