# KataGo WebAssembly spike

An upstream-preserving experiment that compiles KataGo v1.16.5 with its
standard Eigen backend to WebAssembly using Emscripten 6.0.3.

The initial Node.js spike passes both feasibility gates:

- Gate A: the build completes without modifying KataGo source.
- Gate B: a b6c96 network reaches a median 148.45 visits/s on a 9x9 board.

Browser packaging is not implemented yet.

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

## License

The wrapper scripts and documentation are MIT licensed. KataGo and downloaded
model files retain their own licenses.
