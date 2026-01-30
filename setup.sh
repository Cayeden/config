#!/usr/bin/env bash
set -e

# Repo info
REPO_URL="https://github.com/Cayeden/config.git"
TMP_DIR=$(mktemp -d)

# Clone repo
git clone "$REPO_URL" "$TMP_DIR"

# Enter and execute script (adjust script path if needed)
pushd "$TMP_DIR"
chmod +x install.sh
./install.sh
popd

# Clean up
rm -rf "$TMP_DIR"

echo "Repo script executed and temporary clone removed."