# Experimental methodology

## Model and state semantics

The implementation uses a recurrent sparse graph in CSR form. Each edge stores a destination index and a `double` weight. External drive events are generated before timing. Each time step:

1. Propagate events from neurons that spiked on the previous step through outgoing CSR edges.
2. Add external input events.
3. Deduplicate destinations for the current step and accumulate their input.
4. Compute `touched_fraction = number_of_distinct_touched_destinations / N`.
5. Choose a full-scan or lazy state-update path.
6. Apply threshold/reset logic and collect the next spike set.

`FULL` updates all neurons. `LAZY` updates only touched neurons and accounts for elapsed decay when a neuron is next touched. Adaptive policies use the same event set and state semantics.

## Workload schedules

The source partitions the sequence into four equal temporal quarters (`q = t * 4 / T`):

- `LOW_HIGH`: 10% external input activity in the first half, 90% in the second half.
- `HIGH_LOW`: 90% in the first half, 10% in the second half.
- `BURST`: alternates 16-step low/high blocks for `T=64`, and 32-step low/high blocks for `T=128`; low=10%, high=90%.
- `MID_HIGH`: 30% in the first half, 80% in the second half.

Activity is the number of external input events divided by `N` per step. It is not the same as the fraction of targets touched after recurrent propagation. Input target IDs are sampled without replacement within each step, so each external target appears at most once in a step.

## Policies

- `A50`, `A70`, `A90`: use full scan when the current touched fraction is at least 50%, 70%, or 90% respectively.
- `H50_70`: enter full scan at 70% or above; remain there until touched fraction is 50% or below.
- `H70_90`: enter full scan at 90% or above; remain there until touched fraction is 70% or below.

The hysteresis policy begins in lazy mode. The threshold values are fixed constants in this experiment; they are not learned or calibrated online.

## Numerical validation

The full-scan implementation is the reference. Each candidate is run against the same graph and generated drive sequence. Spike vectors are compared exactly. Per-step voltage snapshots are compared using maximum absolute error, with a failure threshold of `1e-12`. Double precision is used for weights, event values, accumulators, and voltages.

The reference and candidate share the same decay-table materialization semantics for stale state. Agreement is empirical over the enumerated cases, not a formal proof of equivalence under arbitrary floating-point execution.

## Timing protocol

For each configuration and method:

- One warm-up execution is performed.
- Seven timed executions are performed.
- The reported time is the median of those seven executions.
- Method order is rotated between repetitions to reduce fixed order bias.
- Three separate executable processes are used for the archived runs.

The timer excludes graph/input construction and vector allocation, but includes event propagation, event accumulation, state updates, and final state materialization. It does not measure energy or whole-application overhead.

## 11.3% calculation

For each held-out `BURST` configuration, take the mean of the three process-level median timings for `FULL`, `LAZY`, and `H50_70`. Define the per-configuration fixed-policy oracle as:

`best_fixed = min(mean_FULL, mean_LAZY)`

Then compute:

`ratio = mean_H50_70 / best_fixed`

The reported workload result is the arithmetic mean of this ratio over four held-out `BURST` configurations. The archived raw logs yield `0.887023`, or an observed reduction of `1 - 0.887023 = 0.112977`, approximately **11.30%**.

The oracle uses the measured result to choose the better of two fixed methods separately for each configuration. It is therefore a strong retrospective benchmark, not a deployable online baseline. The comparison is useful for asking whether a dynamic policy can approach or beat the best fixed choice in these sampled cases, but it must not be presented as a guaranteed real-world speedup.

## Repeated process counts

The “672 + 336” figures count method/reference correctness comparisons across three independent process runs:

- Dynamic: 32 configurations × 7 methods × 3 processes = 672.
- Held-out: 16 configurations × 7 methods × 3 processes = 336.

They are not 672 and 336 unique workload configurations. The underlying configuration counts are 32 and 16 respectively.

## Selection-bias qualification

The `T=128` set uses new graph/input seeds and a longer sequence than the `T=64` dynamic set, so it is useful as a new-seed/longer-sequence follow-up. However, all five adaptive candidates (`A50`, `A70`, `A90`, `H50_70`, `H70_90`) were evaluated on this set, and the strongest periodic-burst result (`H50_70`) was identified after inspecting the set. The set is therefore **not blind with respect to adaptive-policy selection**. The 11.3% result is exploratory and should not be described as a confirmatory result from a preselected policy.

The three process repetitions use identical source-fixed graph and input seeds. They are independent executable process runs, not independent workload samples. The four burst configurations are the distinct configuration count behind the `4/4` win statement.
