# v0.1.0 — Initial reproducible experiment archive

This release publishes a self-contained C++17 experiment package comparing sparse recurrent LIF update policies under dynamic workloads.

## Included

- CSR-based full state scan (`FULL`) and event-driven lazy update (`LAZY`).
- Three single-threshold adaptive policies (`A50`, `A70`, `A90`).
- Two hysteresis policies (`H50_70`, `H70_90`).
- Dynamic workload experiment source (`T=64`) and longer new-seed follow-up (`T=128`).
- Six original process logs, SHA-256 checksums, correctness verifier, build and reproduction scripts.
- Methodology, statistical qualifications, engineering blog draft, and STAR-style resume description.

## Archived checks

- Dynamic set: 224 comparisons per process × 3 processes = 672.
- Longer new-seed set: 112 comparisons per process × 3 processes = 336.
- All archived correctness summaries report zero failures.
- Maximum voltage error reported: `4.4408920985e-16`.

## Main observation

For four periodic-burst configurations in the `N=4096`, `T=128`, density `0.2%` follow-up, `H50_70` reached a mean ratio of `0.887023` against the per-configuration retrospective fixed-policy oracle, corresponding to an observed 11.30% reduction in the timed region.

This is exploratory, not a general guarantee or blind confirmatory result. The adaptive candidates were all evaluated on this follow-up set, and the strongest candidate was identified after inspecting those results. Three process repeats reuse the same fixed graph/input seeds. See `docs/methodology.md` and `results/summary/performance_summary.md` before interpreting the number.

## Reproduce

See `README.md` for compiler requirements, manual build commands, checksum validation, smoke tests, and full reproduction scripts.
