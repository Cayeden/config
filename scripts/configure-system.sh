#!/usr/bin/env bash
set -euo pipefail

# k10temp exposes AMD CPU temperatures. Keep Intel/non-AMD installs portable.
if grep -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
  sudo modprobe k10temp
  printf 'k10temp\n' | sudo tee /etc/modules-load.d/config-cpu-sensors.conf >/dev/null
fi

agent=/usr/lib/polkit-kde-authentication-agent-1
if [[ ! -x "$agent" ]]; then
  echo "Polkit agent is missing; install polkit-kde-agent first." >&2
  exit 1
fi
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && ! pgrep -f '^/usr/lib/polkit-kde-authentication-agent-1( |$)' >/dev/null; then
  nohup "$agent" > "${XDG_RUNTIME_DIR:-/tmp}/polkit-agent-$UID.log" 2>&1 < /dev/null &
fi
