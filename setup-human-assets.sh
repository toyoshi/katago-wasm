#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"
ASSET_DIR="$SCRIPT_DIR/web/assets"
MODEL_FILE="$CACHE_DIR/b18c384nbt-humanv0.bin.gz"
MODEL_URL="https://github.com/lightvector/KataGo/releases/download/v1.15.0/b18c384nbt-humanv0.bin.gz"
MODEL_SHA256="637746e44f0efe00ad1245a50aa9bbf0716efe364c43965ead97bd6835d84ab5"

mkdir -p "$CACHE_DIR" "$ASSET_DIR"
if [ ! -f "$MODEL_FILE" ]; then
  curl -fL --connect-timeout 30 --max-time 1200 \
    -o "$MODEL_FILE.part" "$MODEL_URL"
  mv "$MODEL_FILE.part" "$MODEL_FILE"
fi

if [ "$(sha256sum "$MODEL_FILE" | cut -d ' ' -f 1)" != "$MODEL_SHA256" ]; then
  echo "Error: HumanSL model checksum mismatch: $MODEL_FILE" >&2
  exit 1
fi

cp "$MODEL_FILE" "$ASSET_DIR/human.bin.gz"
cp "$SCRIPT_DIR/analysis.cfg" "$ASSET_DIR/analysis.cfg"

echo "HumanSL browser assets:"
ls -lh "$ASSET_DIR/human.bin.gz" "$ASSET_DIR/analysis.cfg"
