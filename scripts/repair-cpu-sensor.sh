#!/usr/bin/env bash
set -euo pipefail
[[ "$(id -u)" -eq 0 ]] || { echo "Run with sudo or pkexec." >&2; exit 1; }
if ! grep -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
    echo "This repair is for AMD CPUs using k10temp." >&2
    exit 1
fi
vendor=/usr/lib/modprobe.d/zenpower.conf
override=/etc/modprobe.d/zenpower.conf
if [[ -f "$vendor" ]] && grep -Eq '^[[:space:]]*blacklist[[:space:]]+k10temp([[:space:]]|$)' "$vendor" && ! modinfo zenpower >/dev/null 2>&1; then
    if [[ -s "$override" ]]; then
        echo "Existing zenpower override needs manual review: $override" >&2
        exit 1
    fi
    # An /etc file shadows a vendor file with the same name.
    install -Dm644 /dev/null "$override"
fi
modprobe k10temp
mkdir -p /etc/modules-load.d
printf 'k10temp\n' > /etc/modules-load.d/config-cpu-sensors.conf
printf 'k10temp loaded and configured for boot.\n'
