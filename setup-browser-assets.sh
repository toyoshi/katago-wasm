#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"
ASSET_DIR="$SCRIPT_DIR/web/assets"
MODEL_ZIP="$CACHE_DIR/kata1-b6c96-s175395328-d26788732.zip"
MODEL_SHA256="405875c5cfc41ab6b4b5ff818edf3301103d6639fe9bb2c7f2e1489fce5289f4"

if [ ! -f "$MODEL_ZIP" ]; then
  echo "Error: run ./benchmark.sh once to download the model" >&2
  exit 1
fi

if [ "$(sha256sum "$MODEL_ZIP" | cut -d ' ' -f 1)" != "$MODEL_SHA256" ]; then
  echo "Error: model archive checksum mismatch: $MODEL_ZIP" >&2
  exit 1
fi

mkdir -p "$ASSET_DIR"
unzip -p "$MODEL_ZIP" '*/model.txt.gz' > "$ASSET_DIR/model.txt.gz"
cp "$SCRIPT_DIR/benchmark.cfg" "$ASSET_DIR/benchmark.cfg"

echo "Browser data assets:"
ls -lh "$ASSET_DIR/model.txt.gz" "$ASSET_DIR/benchmark.cfg"
