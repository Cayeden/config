#!/usr/bin/env bash
# ponytail: greps warp-cli's human text output, no JSON API exposed to parse instead
# note: 5s poll interval can miss a connecting/disconnecting phase shorter than that

status=$(warp-cli --accept-tos status 2>/dev/null | head -1)

case "$status" in
  "Status update: Connected")
    echo '{"text":"","tooltip":"WARP: Connected — click to disconnect","class":"connected"}' ;;
  "Status update: Connecting"*|"Status update: Disconnecting"*)
    echo '{"text":"","tooltip":"WARP: '"${status#Status update: }"'…","class":"connecting"}' ;;
  *)
    echo '{"text":"","tooltip":"WARP: Disconnected — click to connect","class":"disconnected"}' ;;
esac
