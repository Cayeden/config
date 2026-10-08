#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
[[ "$(id -u)" -ne 0 ]] || { echo 'Run as your normal user.' >&2; exit 1; }
[[ "$(uname -m)" == x86_64 ]] || { echo 'This installer supports x86_64.' >&2; exit 1; }
version=1.18.35
checksum='xACTd596NBnTvG+rmMmoeIRtUh8uFSLr8LQepBwfGizabCTa1kAhSCxuJwKSlBoHLyDbaYFhycVDyGKlVoqSLQ=='
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
app="$data_home/opencode-desktop/OpenCode.AppImage"
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
verify() {
    python3 - "$1" "$checksum" <<'PY'
import base64, hashlib, sys
from pathlib import Path
p = Path(sys.argv[1])
actual = base64.b64encode(hashlib.sha512(p.read_bytes()).digest()).decode() if p.is_file() else ''
sys.exit(0 if actual == sys.argv[2] else 1)
PY
}
if ! verify "$app"; then
    curl -fL --retry 3 "https://github.com/anomalyco/opencode/releases/download/v$version/opencode-desktop-linux-x86_64.AppImage" -o "$temp/OpenCode.AppImage"
    verify "$temp/OpenCode.AppImage" || { echo 'Release checksum mismatch.' >&2; exit 1; }
    install -Dm755 "$temp/OpenCode.AppImage" "$app"
fi
(cd "$temp" && "$app" --appimage-extract 'usr/share/icons/*' >/dev/null)
for size in 32 64 128; do
    icon="hicolor/${size}x${size}/apps/ai.opencode.desktop.png"
    install -Dm644 "$temp/squashfs-root/usr/share/icons/$icon" "$data_home/icons/$icon"
done
./scripts/configure-desktop.sh
echo "OpenCode Desktop $version installed. Launch OpenCode from your application menu."
