# KataGo WebAssembly spike

An upstream-preserving experiment that compiles KataGo v1.16.5 with its
standard Eigen backend to WebAssembly using Emscripten 6.0.3.

The initial Node.js spike passes both feasibility gates:

- Gate A: the build completes without modifying KataGo source.
- Gate B: a b6c96 network reaches a median 148.45 visits/s on a 9x9 board.

An experimental zero-dependency browser benchmark is also included.

## Requirements

- Linux
- Git, CMake, Make, curl, tar, and unzip
- Enough memory and disk space to compile KataGo

Node.js and the compiler toolchain are supplied by emsdk.

## Reproduce

```sh
./setup.sh
./build.sh
./benchmark.sh
```

`setup.sh` downloads these fixed inputs into the ignored `.cache/` directory:

- Emscripten 6.0.3
- KataGo v1.16.5
- Eigen 3.4.0
- Emscripten's zlib port

`benchmark.sh` downloads `kata1-b6c96-s175395328-d26788732`, then measures one
built-in 9x9 position at 400 visits with one search, Eigen, and NN server
thread. Generated files stay under `.cache/` and `build/`.

## Build notes

KataGo's source tree remains clean before and after every build. The build
wrapper supplies the compatibility settings that upstream CMake does not:

- `-msimd128` for Eigen vectorization
- explicit little-endian preprocessor definitions
- Emscripten zlib through `-sUSE_ZLIB=1`
- an empty `libatomic.a`, because WebAssembly atomics are compiler intrinsics
  but KataGo's generic Clang branch still requests `-latomic`
- pthread pool and 8 MiB worker stacks
- Node raw filesystem access for the CLI benchmark

See [BENCHMARK.md](BENCHMARK.md) for results and limitations.

Browser build adds:

- `-sMODULARIZE -sEXPORT_ES6 -sINVOKE_RUN=0`: ES6 modular factory, no auto-run
- `-sFORCE_FILESYSTEM -sPTHREAD_POOL_SIZE=8 -sSTACK_SIZE=8388608`: virtual FS and pthreads
- `-msimd128`: SIMD vectorization
- `-sALLOW_MEMORY_GROWTH=1`: dynamic memory expansion
- `-sPROXY_TO_PTHREAD=1` keeps the browser main thread responsive
- No `NODERAWFS`: model and config data are written to Emscripten MEMFS

## Browser build

```sh
./build-browser.sh
./setup-browser-assets.sh
python3 serve.py
```

Open http://127.0.0.1:8080/ in a browser. The UI loads the WASM module via ES
module import from `web/assets/`, places the verified model and config into Emscripten's
virtual filesystem, and runs the same 9x9/400-visit benchmark as the Node
build.

An optional Selenium smoke test runs the complete benchmark in a headless
browser while the server is running:

```sh
python3 tests/browser_smoke.py --browser firefox
python3 tests/browser_smoke.py --browser chrome
```

Measured medians on the development host were 141.11 visits/s in Firefox 153
and 156.17 visits/s in Chromium 150. See [BENCHMARK.md](BENCHMARK.md).

## License

The wrapper scripts and documentation are MIT licensed. KataGo and downloaded
model files retain their own licenses.
