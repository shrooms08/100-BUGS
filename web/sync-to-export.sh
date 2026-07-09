#!/usr/bin/env bash
# Copy the web sidecar files (vendored bundles, config, wallet flow) into
# the export folder next to index.html.
#
# Godot only emits index.* on export; these custom files are NOT managed
# by the exporter, so they must be copied after every re-export. The
# <script> tags that load them are injected automatically via
# export_presets.cfg -> html/head_include = "web/head_include.html".
#
# Run from the project root:  bash web/sync-to-export.sh
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
src="$here/web"
dst="$here/export"

mkdir -p "$dst/vendor"
cp "$src/vendor/buffer.js" "$dst/vendor/buffer.js"
cp "$src/vendor/solana-web3.iife.min.js" "$dst/vendor/solana-web3.iife.min.js"
cp "$src/config.js" "$dst/config.js"
cp "$src/wallet.js" "$dst/wallet.js"

echo "synced web/ sidecar files -> export/"
ls -la "$dst/vendor" "$dst/config.js" "$dst/wallet.js"
