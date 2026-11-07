# Lazy LIF Dynamic

**A reproducible C++17 study of sparse event-driven LIF updates under dynamic workloads.**

> Independent engineering experiment. The repository reports measured behavior on one execution environment; it does not claim a universally faster algorithm or a new neural-network paradigm.

## What is this?

This project compares seven update policies for a sparse, recurrent LIF-style network:

- `FULL`: scan and update every neuron at every time step. Recurrent propagation still uses the CSR graph.
- `LAZY`: update only neurons touched by external input or recurrent events; materialize delayed decay when a neuron is next touched.
- `A50`, `A70`, `A90`: switch to `FULL` when the fraction of distinct touched targets in the current step reaches 50%, 70%, or 90%; otherwise use `LAZY`.
- `H50_70`: hysteresis policy; enter `FULL` at 70%, return to `LAZY` at 50% or below.
- `H70_90`: hysteresis policy; enter `FULL` at 90%, return to `LAZY` at 70% or below.

The touched-target fraction is computed **after combining recurrent events and external input events**, counting each destination at most once per step.

This benchmark does **not** include a Dense-BLAS matrix-multiplication implementation. `FULL` is a full neuron-state scan with sparse CSR event propagation. Do not describe it as Dense-BLAS.

## Main observation

In the held-out workload set (`N=4096`, `T=128`, density `0.2%`, new graph/input seeds), the periodic-burst schedule produced the strongest result for `H50_70`:

- Mean ratio to the per-configuration best fixed policy: **0.887023**.
- Equivalent observed reduction in kernel time: **11.30%**.
- Wins against that per-configuration fixed-policy oracle: **4/4 configurations**.

The oracle is `min(mean(FULL), mean(LAZY))` for each configuration, where each method's mean is calculated across three independent process runs (each process reports the median of seven timed repetitions). This is an intentionally strong, retrospective reference, **not an implementable online policy**. Therefore the 11.3% figure is a bounded observation, not a general guarantee.

The same held-out set also shows limits: in the `MID_HIGH` workload, hysteresis policies did not consistently beat the fixed-policy oracle. See [methodology and limitations](docs/methodology.md) and [performance summary](results/summary/performance_summary.md).

## Repository layout

```text
lazy-lif-dynamic/
├── README.md
├── LICENSE
├── CMakeLists.txt
├── src/
│   ├── dynamic_v2.cpp
│   └── holdout_v2.cpp
├── scripts/
│   ├── run_all.sh
│   └── verify_logs.sh
├── results/
│   ├── SHA256SUMS
│   ├── raw/
│   └── summary/
│       └── performance_summary.md
└── docs/
    ├── archive_audit.md
    ├── blog.md
    ├── methodology.md
    ├── resume_project.md
    ├── github_release.md
    └── release_notes_v0.1.0.md
```

## Requirements

- Linux or another environment with a working C++17 compiler.
- GCC or Clang. The archived measurements used GCC 14.2.0.
- Standard C++ library only; no Python, BLAS, or third-party dependency is required.
- `bash`, `sha256sum`, and `awk` for the helper scripts.

## Compile manually

From the repository root:

```bash
mkdir -p build

g++ -O3 -march=native -std=c++17 -DNDEBUG \
  src/dynamic_v2.cpp -o build/dynamic_v2

g++ -O3 -march=native -std=c++17 -DNDEBUG \
  src/holdout_v2.cpp -o build/holdout_v2
```

`-march=native` tunes the executable for the current CPU. For a portable binary, omit that flag. Performance numbers will not be directly comparable across CPUs, compilers, operating systems, or power states.

## Reproduce the archived experiment design

The full script compiles both programs and runs each executable three times as separate processes:

```bash
bash scripts/run_all.sh
```

It writes fresh logs to `results/reproduced/`. It does not overwrite the archived raw logs in `results/raw/`.

To run only one executable manually:

```bash
./build/dynamic_v2 > dynamic_repro_run1.log
./build/holdout_v2 > holdout_repro_run1.log
```

Each process performs correctness checks first, then benchmarks. Every benchmark row is the median of seven timed repetitions after a warm-up. The three-process design provides independent process-level repeats; it does not create new random seeds because the seeds are fixed in the source.

### Dynamic set: 672 correctness comparisons total

Per process:

- `N=4096`, `T=64`.
- Densities: `0.05%`, `0.2%`.
- Graph seeds: `11`, `22`.
- Input seeds: `101`, `202`.
- Schedules: `LOW_HIGH`, `HIGH_LOW`, `BURST`, `MID_HIGH`.
- Seven methods compared with `FULL`.
- `2 × 2 × 2 × 4 = 32` input configurations; `32 × 7 = 224` method/reference comparisons per process.

Three separate process runs produce `224 × 3 = 672` correctness comparisons and 672 benchmark rows. Each process log contains `CHECK_SUMMARY,groups=224` and `BENCH_SUMMARY,rows=224,repeats=7`.

### Held-out set: 336 correctness comparisons total

Per process:

- `N=4096`, `T=128`.
- Density: `0.2%` only.
- New graph seeds: `33`, `44`.
- New input seeds: `303`, `404`.
- Same four schedules and seven methods.
- `1 × 2 × 2 × 4 = 16` input configurations; `16 × 7 = 112` comparisons per process.

Three separate process runs produce `112 × 3 = 336` correctness comparisons and 336 benchmark rows. Each process log contains `CHECK_SUMMARY,groups=112` and `BENCH_SUMMARY,rows=112,repeats=7`.

The held-out set is new in seeds and sequence length, but is **not** a broad cross-hardware or cross-density validation.

## Correctness criteria

Each method is compared against `FULL` on the same graph and exact input event sequence:

- Spike outputs must match exactly (`mismatch=0`).
- Captured per-step voltage snapshots must have maximum absolute error no greater than `1e-12`.
- The archived logs report zero failures and maximum observed error `4.4408920985e-16` in each process for both experiment sets.

This supports numerical agreement for the tested cases; it is not a formal proof for all possible inputs, thresholds, sequence lengths, or floating-point environments.

## What the timing includes

The timed region includes per-step recurrent event propagation over CSR edges, external event ingestion, target marking/accumulation, the selected neuron-state update path, and final state materialization. Graph construction, drive generation, and result-vector allocation occur outside the timed region. This is a kernel/rollout benchmark, not an end-to-end application benchmark.

## Reproduction checks

```bash
bash scripts/verify_logs.sh results/raw
sha256sum -c results/SHA256SUMS
```

For newly reproduced logs, inspect each `CHECK_SUMMARY` and `BENCH_SUMMARY`. Timing values are expected to vary; correctness counts and failure status should remain stable.

## Limitations

- One container CPU environment; no claim of cross-platform performance.
- The held-out experiment covers only one connection density.
- Four workload schedules and two graph/input seeds per configuration are a small sample.
- The best-fixed oracle is retrospective and cannot be selected online without prior knowledge of the configuration.
- The current adaptive selector uses the current step's touched-target fraction; it does not forecast future activity.
- The benchmark does not measure energy, power, memory bandwidth, GPU performance, or end-to-end product latency.
- This repository's dynamic experiment does not include Dense-BLAS or SIMD dense baselines.
- Existing event-driven and lazy-update ideas have prior art; this project is an engineering exploration, not a novelty or priority claim.

## License

Code is released under the MIT License. Raw benchmark logs and documentation are included under the same license unless a separate notice is added. See [LICENSE](LICENSE).

### Important statistical qualification

The `T=128` new-seed set is held out by graph/input seed and sequence length relative to the initial `T=64` set, but it is **not policy-selection-blind**: all five adaptive candidates are evaluated on it, and `H50_70` is identified as the strongest periodic-burst candidate after inspecting those results. Thus 11.3% is an exploratory best-observed result, not a pre-registered confirmatory estimate. Three process repeats reuse the same fixed graph/input seeds; they improve timing repeatability but do not triple the number of independent workload samples.
