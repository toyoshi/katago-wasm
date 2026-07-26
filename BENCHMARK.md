# Benchmark results

Measured on 2026-07-26.

## Environment

| Item | Value |
| --- | --- |
| Host architecture | aarch64 |
| CPU | ARM Cortex-X925 / Cortex-A725, 20 cores |
| Emscripten | 6.0.3 |
| Node.js | 22.16.0 (emsdk) |
| KataGo | v1.16.5 |
| Backend | Eigen CPU |
| Network | kata1-b6c96-s175395328-d26788732, model version 8 |
| Board | 9x9 built-in benchmark position |
| Search | 400 visits, 1 search thread, batch size 1 |

## Gate A

**PASS.** The Emscripten build produced:

| File | Size |
| --- | ---: |
| `katago.js` | 132 KiB |
| `katago.wasm` | 5.4 MiB |

`git status --short` in the KataGo source tree was empty after the build.

## Gate B

The acceptance threshold was 130 visits/s, equivalent to 400 visits in at
most about 3 seconds.

With WebAssembly SIMD enabled:

| Run | visits/s | Reported time |
| ---: | ---: | ---: |
| 1 | 148.23 | 2.7 s |
| 2 | 148.45 | 2.7 s |
| 3 | 148.66 | 2.7 s |
| 4 | 146.88 | 2.7 s |
| 5 | 149.39 | 2.7 s |
| Median | **148.45** | **2.7 s** |
| Mean | **148.32** | **2.7 s** |

**PASS.** The median is 14.2% above the 130 visits/s threshold.

For comparison, the same build without `-msimd128` measured 101.36-109.82
visits/s, with a median of 106.02 visits/s. SIMD is necessary to pass this
gate on this host.

## Limitations

- The benchmark uses one position. More positions and devices are needed
  before drawing broad performance conclusions.
- pthreads require cross-origin isolation headers in browsers.
- Safari and iPad behavior has not been tested.
- `NODERAWFS` remains CLI-only; the browser build loads data into MEMFS.

## Browser results

The browser build uses MEMFS, WebAssembly SIMD, eight preallocated pthread
workers, and `PROXY_TO_PTHREAD`. Each browser was run three times sequentially
with a fresh page and module instance for every run.

| Browser | Run 1 | Run 2 | Run 3 | Median |
| --- | ---: | ---: | ---: | ---: |
| Firefox 153.0 | 142.44 | 141.11 | 138.28 | **141.11 visits/s** |
| Chromium 150.0.7871.128 | 149.92 | 159.74 | 156.17 | **156.17 visits/s** |

Both browsers pass the 130 visits/s threshold on this host. The Selenium smoke
test also verifies cross-origin isolation, model loading, pthread execution,
process exit, and rendering of the measured result.

## HumanSL results

The official `b18c384nbt-humanv0.bin.gz` model loads successfully as model
version 15. Its compressed size is 99,066,230 bytes (94.5 MiB), with SHA-256
`637746e44f0efe00ad1245a50aa9bbf0716efe364c43965ead97bd6835d84ab5`.

Using HumanSL as the primary search model is not practical on this backend:

| Mode | Result |
| --- | ---: |
| HumanSL primary, 400 visits | 5.05 visits/s, 79.3 s |
| Dual-model analysis, 5 distinct positions | 4.32 s including startup |
| Estimated warm HumanSL policy latency | about 0.2 s per position |
| Firefox, local asset load plus one policy | 4.89 s |
| Chromium, local asset load plus one policy | 4.68 s |

The dual-model path returns both `policy` and `humanPolicy`, which matches the
intended application architecture: search with the small normal model and use
HumanSL only for the extra policy evaluation. The browser timings use a local
HTTP server and do not include a real-world 94.5 MiB internet download.
