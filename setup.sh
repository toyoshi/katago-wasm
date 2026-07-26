#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"
EMSDK_DIR="$CACHE_DIR/emsdk"
EIGEN_DIR="$CACHE_DIR/eigen-3.4.0"
KATAGO_DIR="$CACHE_DIR/KataGo"
EMSDK_VERSION="6.0.3"
KATAGO_VERSION="v1.16.5"
KATAGO_COMMIT="ba938676d7f42d70950b3a535af2466fb642008c"
EIGEN_VERSION="3.4.0"
EIGEN_COMMIT="3147391d946bb4b6c68edd901f2add6ac1f31f8c"

# Clone emsdk
if [ ! -d "$EMSDK_DIR/.git" ]; then
  echo "=== Cloning emsdk ==="
  mkdir -p "$CACHE_DIR"
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$EMSDK_DIR"
else
  echo "emsdk already cloned"
fi

# Install and activate emsdk
cd "$EMSDK_DIR"
echo "=== Installing emsdk ==="
./emsdk install "$EMSDK_VERSION"
./emsdk activate "$EMSDK_VERSION"

# Source environment
export EMSDK_QUIET=1
# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh" > /dev/null
echo "Emscripten version: $(emcc --version)"

# Build zlib for emscripten
echo "=== Building zlib for emscripten ==="
embuilder build zlib

# Clone Eigen
if [ ! -d "$EIGEN_DIR/.git" ]; then
  if [ -e "$EIGEN_DIR" ]; then
    echo "Error: $EIGEN_DIR exists but is not a Git checkout" >&2
    exit 1
  fi
  echo "=== Cloning Eigen $EIGEN_VERSION ==="
  git clone --depth 1 --branch "$EIGEN_VERSION" \
    https://gitlab.com/libeigen/eigen.git "$EIGEN_DIR"
fi

if [ "$(git -C "$EIGEN_DIR" rev-parse HEAD)" != "$EIGEN_COMMIT" ]; then
  echo "Error: Eigen checkout does not match $EIGEN_COMMIT" >&2
  exit 1
fi

if [ -n "$(git -C "$EIGEN_DIR" status --short)" ]; then
  echo "Error: Eigen source has local modifications" >&2
  git -C "$EIGEN_DIR" status --short >&2
  exit 1
fi

# Clone KataGo
if [ ! -d "$KATAGO_DIR/.git" ]; then
  echo "=== Cloning KataGo ==="
  git clone --depth 1 --branch "$KATAGO_VERSION" https://github.com/lightvector/KataGo.git "$KATAGO_DIR"
else
  echo "KataGo already cloned"
fi

if [ "$(git -C "$KATAGO_DIR" rev-parse HEAD)" != "$KATAGO_COMMIT" ]; then
  echo "Error: KataGo checkout does not match $KATAGO_COMMIT ($KATAGO_VERSION)" >&2
  exit 1
fi

if [ -n "$(git -C "$KATAGO_DIR" status --short)" ]; then
  echo "Error: KataGo source has local modifications" >&2
  git -C "$KATAGO_DIR" status --short >&2
  exit 1
fi

echo "=== Setup complete ==="
echo "emsdk: $EMSDK_DIR"
echo "Eigen: $EIGEN_DIR"
echo "KataGo: $KATAGO_DIR"
