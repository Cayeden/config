#!/usr/bin/env bash
# Activate Riseup's tray item to restore even a hidden window.
if pgrep -x riseup-vpn >/dev/null; then
  while read -r service; do
    if busctl --user call "$service" /StatusNotifierItem org.kde.StatusNotifierItem Activate ii 0 0 >/dev/null 2>&1; then
      break
    fi
  done < <(busctl --user --no-pager --no-legend list | awk '$3 == "riseup-vpn" && $1 ~ /^:/ {print $1}')
  hyprctl dispatch focuswindow 'class:^net\.riseup\.riseup-vpn$' >/dev/null 2>&1
  exit 0
fi
exec riseup-vpn
