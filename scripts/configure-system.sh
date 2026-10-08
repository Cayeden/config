#!/usr/bin/env bash
set -euo pipefail

# k10temp exposes AMD CPU temperatures. Keep Intel/non-AMD installs portable.
if grep -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
  sudo modprobe k10temp
  printf 'k10temp\n' | sudo tee /etc/modules-load.d/config-cpu-sensors.conf >/dev/null
fi
