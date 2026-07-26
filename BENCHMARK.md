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

- These are Node.js results, not browser measurements.
- The benchmark uses one position. More positions and browser/device runs are
  needed before drawing broad performance conclusions.
- pthreads require cross-origin isolation headers in browsers.
- Safari and iPad behavior has not been tested.
- HumanSL model loading and performance have not been tested.
- `NODERAWFS` is intentionally CLI-specific and must be replaced by a browser
  model-loading strategy.
