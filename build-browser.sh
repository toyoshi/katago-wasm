#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"
BUILD_DIR="$SCRIPT_DIR/build-browser"
ASSET_DIR="$SCRIPT_DIR/web/assets"
EMSDK_DIR="$CACHE_DIR/emsdk"
EIGEN_DIR="$CACHE_DIR/eigen-3.4.0"
KATAGO_DIR="$CACHE_DIR/KataGo"
SHIM_DIR="$CACHE_DIR/shims"

echo "=== Setting up emsdk ==="
export EMSDK_QUIET=1
# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh" > /dev/null

for source_dir in "$KATAGO_DIR" "$EIGEN_DIR"; do
  if [ -n "$(git -C "$source_dir" status --short)" ]; then
    echo "Error: refusing to build modified source: $source_dir" >&2
    git -C "$source_dir" status --short >&2
    exit 1
  fi
done

# KataGo's generic Clang branch requests libatomic even though Wasm atomics
# are compiler intrinsics.
mkdir -p "$SHIM_DIR" "$BUILD_DIR" "$ASSET_DIR"
emar rcs "$SHIM_DIR/libatomic.a"

echo "=== Configuring browser build ==="
emcmake cmake -S "$KATAGO_DIR/cpp" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DEMSCRIPTEN_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_CXX_FLAGS="-sUSE_ZLIB=1 -pthread -fexceptions -msimd128 -DBYTE_ORDER=1234 -DLITTLE_ENDIAN=1234 -DBIG_ENDIAN=4321" \
  -DCMAKE_EXE_LINKER_FLAGS="-sUSE_ZLIB=1 -pthread -fexceptions -msimd128 -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createKataGo -sINVOKE_RUN=0 -sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS,callMain -sENVIRONMENT=web,worker -sPROXY_TO_PTHREAD=1 -sPTHREAD_POOL_SIZE=8 -sSTACK_SIZE=8388608 -sDEFAULT_PTHREAD_STACK_SIZE=8388608 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=268435456 -sEXIT_RUNTIME=1 -L$SHIM_DIR" \
  -DUSE_BACKEND=EIGEN \
  -DNO_GIT_REVISION=1 \
  -DEIGEN3_INCLUDE_DIRS="$EIGEN_DIR" \
  -DBUILD_DISTRIBUTED=OFF

echo "=== Building browser module ==="
emmake cmake --build "$BUILD_DIR" --parallel "$(nproc)"

cp "$BUILD_DIR/katago.js" "$ASSET_DIR/katago.js"
cp "$BUILD_DIR/katago.wasm" "$ASSET_DIR/katago.wasm"

for source_dir in "$KATAGO_DIR" "$EIGEN_DIR"; do
  if [ -n "$(git -C "$source_dir" status --short)" ]; then
    echo "Error: build modified source: $source_dir" >&2
    exit 1
  fi
done

echo "Browser assets:"
ls -lh "$ASSET_DIR/katago.js" "$ASSET_DIR/katago.wasm"
