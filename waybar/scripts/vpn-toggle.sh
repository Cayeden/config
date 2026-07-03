#!/usr/bin/env bash
if warp-cli --accept-tos status 2>/dev/null | grep -q "^Status update: Connected"; then
  warp-cli --accept-tos disconnect >/dev/null 2>&1
else
  warp-cli --accept-tos connect >/dev/null 2>&1
fi
