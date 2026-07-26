#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CACHE_DIR="$SCRIPT_DIR/.cache"
EMSDK_DIR="$CACHE_DIR/emsdk"
MODEL_ZIP="$CACHE_DIR/kata1-b6c96-s175395328-d26788732.zip"
MODEL_FILE="$CACHE_DIR/kata1-b6c96-s175395328-d26788732.txt.gz"
MODEL_URL="https://media.katagotraining.org/uploaded/networks/zips/kata1/kata1-b6c96-s175395328-d26788732.zip"
MODEL_SHA256="405875c5cfc41ab6b4b5ff818edf3301103d6639fe9bb2c7f2e1489fce5289f4"

if [ ! -f "$BUILD_DIR/katago.wasm" ]; then
  echo "Error: katago.wasm not found. Run ./build.sh first."
  exit 1
fi

export EMSDK_QUIET=1
# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh" > /dev/null

if [ ! -f "$MODEL_ZIP" ]; then
  curl -fL --connect-timeout 30 --max-time 300 \
    -o "$MODEL_ZIP.part" "$MODEL_URL"
  mv "$MODEL_ZIP.part" "$MODEL_ZIP"
fi

if [ "$(sha256sum "$MODEL_ZIP" | cut -d ' ' -f 1)" != "$MODEL_SHA256" ]; then
  echo "Error: model archive checksum mismatch: $MODEL_ZIP" >&2
  exit 1
fi

unzip -p "$MODEL_ZIP" '*/model.txt.gz' > "$MODEL_FILE"

echo "=== Running Gate B benchmark ==="
echo "Model: $MODEL_FILE"
echo "WASM: $BUILD_DIR/katago.wasm"

node "$BUILD_DIR/katago.js" benchmark \
  -model "$MODEL_FILE" \
  -config "$SCRIPT_DIR/benchmark.cfg" \
  -v 400 \
  -t 1 \
  -n 1 \
  -boardsize 9 \
  -fixed-batch-size 1

echo "=== Benchmark complete ==="
