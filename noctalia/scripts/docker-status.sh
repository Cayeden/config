#!/usr/bin/env bash

if ! running=$(docker ps --format '{{.Names}}  —  {{.Status}}' 2>/dev/null); then
  jq -nc '{text:"󰡨 –", tooltip:"Docker daemon not running", class:"down"}'
  exit 0
fi

if [ -z "$running" ]; then
  count=0
  tooltip="No running containers"
else
  count=$(grep -c . <<< "$running")
  tooltip="$count running:"$'\n'"$running"
fi

jq -nc --arg n "$count" --arg tip "$tooltip" '{text:"󰡨 \($n)", tooltip:$tip, class:"up"}'
