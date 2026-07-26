#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"
BUILD_DIR="$SCRIPT_DIR/build"
EMSDK_DIR="$CACHE_DIR/emsdk"
EIGEN_DIR="$CACHE_DIR/eigen-3.4.0"
KATAGO_DIR="$CACHE_DIR/KataGo"
SHIM_DIR="$CACHE_DIR/shims"

# Setup emsdk environment
echo "=== Setting up emsdk ==="
export EMSDK_QUIET=1
# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh" > /dev/null
echo "Emscripten version: $(emcc --version)"
echo "Node.js version: $(node --version)"

if [ -n "$(git -C "$KATAGO_DIR" status --short)" ]; then
  echo "Error: refusing to build modified KataGo source" >&2
  git -C "$KATAGO_DIR" status --short >&2
  exit 1
fi

# KataGo's generic Clang branch links libatomic. Wasm atomics are compiler
# intrinsics, so an empty archive satisfies the unnecessary library lookup.
mkdir -p "$SHIM_DIR"
emar rcs "$SHIM_DIR/libatomic.a"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "=== Configuring with CMake ==="
emcmake cmake "$KATAGO_DIR/cpp" \
  -DCMAKE_TOOLCHAIN_FILE="$EMSDK_DIR/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DEMSCRIPTEN_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_CXX_FLAGS="-sUSE_ZLIB=1 -pthread -fexceptions -msimd128 -DBYTE_ORDER=1234 -DLITTLE_ENDIAN=1234 -DBIG_ENDIAN=4321" \
  -DCMAKE_EXE_LINKER_FLAGS="-sUSE_ZLIB=1 -pthread -fexceptions -msimd128 -sNODERAWFS=1 -sPTHREAD_POOL_SIZE=8 -sSTACK_SIZE=8388608 -sDEFAULT_PTHREAD_STACK_SIZE=8388608 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=268435456 -sEXIT_RUNTIME=1 -L$SHIM_DIR" \
  -DUSE_BACKEND=EIGEN \
  -DNO_GIT_REVISION=1 \
  -DEIGEN3_INCLUDE_DIRS="$EIGEN_DIR" \
  -DBUILD_DISTRIBUTED=OFF

# Build
echo "=== Building ==="
emmake make -j"$(nproc)"

echo "=== Build complete ==="
echo "WASM output: $BUILD_DIR/katago.wasm"
ls -lh "$BUILD_DIR/katago.wasm" 2>/dev/null || echo "katago.wasm not found"

if [ -n "$(git -C "$KATAGO_DIR" status --short)" ]; then
  echo "Error: build modified KataGo source" >&2
  git -C "$KATAGO_DIR" status --short >&2
  exit 1
fi
