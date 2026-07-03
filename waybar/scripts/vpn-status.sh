#!/usr/bin/env bash
# ponytail: greps warp-cli's human text output, no JSON API exposed to parse instead

if warp-cli --accept-tos status 2>/dev/null | grep -q "^Status update: Connected"; then
  echo '{"text":"","tooltip":"WARP: Connected — click to disconnect","class":"connected"}'
else
  echo '{"text":"","tooltip":"WARP: Disconnected — click to connect","class":"disconnected"}'
fi
