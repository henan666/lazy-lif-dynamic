# Archive audit record

Audit performed against the original C++ source and log files present in the execution container before packaging.

## Count reconciliation

| Experiment | Configurations / process | Methods | Process runs | Comparisons total | Raw logs |
|---|---:|---:|---:|---:|---|
| Dynamic (`T=64`) | 32 | 7 | 3 | 672 | `results/raw/dynamic_run1..3.log` |
| Held-out (`T=128`) | 16 | 7 | 3 | 336 | `results/raw/holdout_run1..3.log` |

Important: 672 and 336 are repeated method/reference comparisons across three process runs, not unique workload configurations.

## Original source hashes

- `dynamic_v2.cpp`: `5b0a978fcdd13879f7027ab9a0f4e5e9eb7858b7d69a06c904242da3718d87d0`
- `holdout_v2.cpp`: `ca53bb5057c8dd3ff484eda00d7f2d71e80b6319648e25484e1f707b630de6a5`

## Archived correctness summaries

All six raw logs were checked. Dynamic logs each report 224 comparisons, zero failures, maximum error `4.4408920985e-16`, and 224 benchmark rows with seven repeats. Held-out logs each report 112 comparisons, zero failures, the same maximum error, and 112 benchmark rows with seven repeats.

## Package smoke tests

The packaged `src/dynamic_v2.cpp` and `src/holdout_v2.cpp` were compiled with:

`g++ -O3 -march=native -std=c++17 -DNDEBUG`

Each packaged executable was run once. Both reproduced their expected correctness and benchmark row counts with zero failures. These smoke-test logs are temporary validation outputs and are not substituted for the six archived original logs.

## Scope cautions

- The dynamic experiment's `FULL` mode is a full state scan over a CSR-propagated sparse network, not Dense-BLAS.
- The 11.3% figure is computed on four held-out periodic-burst configurations against a per-configuration retrospective `min(FULL, LAZY)` oracle.
- The held-out set uses one density and two graph/input seeds; it is not broad statistical validation.

## Statistical qualification

The `T=128` follow-up uses new seeds and longer sequences, but adaptive policy candidates were compared on that same set; the best periodic-burst candidate was identified after looking at those measurements. It is not blind with respect to policy selection. The 11.3% result must be described as exploratory. Three process runs reuse the same fixed seeds and are not independent workload samples.
