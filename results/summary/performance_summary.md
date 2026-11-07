# Archived performance summary

All ratios below are recomputed from the six archived raw logs by averaging each method's three process-level median times per configuration, then comparing adaptive methods with the per-configuration fixed-policy oracle `min(mean(FULL), mean(LAZY))`. Values are arithmetic means over configurations within each schedule.

## Held-out set (`N=4096`, `T=128`, density 0.2%)

| Schedule | Policy | Mean ratio to best fixed | Wins / 4 configs |
|---|---|---:|---:|
| LOW_HIGH | A70 | 0.876767 | 4/4 |
| HIGH_LOW | A90 | 0.894986 | 4/4 |
| BURST | H50_70 | **0.887023** | **4/4** |
| MID_HIGH | H70_90 | 1.007114 | 1/4 |

The `BURST` result corresponds to approximately 11.30% lower timed-region runtime than the retrospective fixed-policy oracle for these four configurations. It is not a universal speedup claim.

## Initial dynamic set (`N=4096`, `T=64`, densities 0.05% and 0.2%)

| Schedule | Policy | Mean ratio to best fixed | Wins / 8 configs |
|---|---|---:|---:|
| LOW_HIGH | A70 | 0.964214 | 5/8 |
| HIGH_LOW | A70 | 0.948204 | 7/8 |
| BURST | H50_70 | 0.968644 | 6/8 |
| MID_HIGH | H50_70 | 0.961208 | 4/8 |

The initial set is less decisive: the apparent held-out burst result should be presented as a result from a small, specific test set, not as an established general effect.

## Correctness totals

| Set | Per process | Process runs | Total method/reference comparisons | Failures |
|---|---:|---:|---:|---:|
| Dynamic | 224 | 3 | 672 | 0 |
| Held-out | 112 | 3 | 336 | 0 |

Maximum voltage error reported in each process: `4.4408920985e-16`. Spike mismatches: zero.

## Statistical qualification

The `T=128` set uses new seeds and a longer sequence than the initial set, but all adaptive candidates were evaluated on it. `H50_70` was identified after inspecting those results, so the 11.3% figure is an exploratory best-observed candidate result, not a policy-selection-blind confirmation. The three process runs reuse identical seeds; they are repeated measurements, not three independent workload samples. There are four distinct periodic-burst configurations behind the `4/4` count.
