# GitHub first-publication checklist

## Repository identity

- **Repository name:** `lazy-lif-dynamic`
- **Short description:** `Reproducible C++17 experiments on sparse event-driven LIF updates under dynamic workloads.`
- **Suggested topics:** `cpp`, `cpp17`, `performance-benchmark`, `sparse-computation`, `event-driven`, `lif-neuron`, `csr`, `reproducible-research`
- **Visibility:** Public
- **License:** MIT (confirm that all newly added third-party material, if any, is compatible before publishing)

## Before creating the public repository

- [x] Source files included.
- [x] Six archived raw logs included.
- [x] SHA-256 manifest included and verified.
- [x] Build instructions included.
- [x] Reproduction scripts included.
- [x] Correctness criteria and numerical tolerance documented.
- [x] The `FULL` implementation is explicitly distinguished from Dense-BLAS.
- [x] The 11.3% result is labeled exploratory and tied to four burst configurations.
- [x] Repeated process runs are not misrepresented as independent workload samples.
- [x] Limitations and unmeasured quantities are documented.
- [ ] Run the complete `bash scripts/run_all.sh` on the publisher's target machine and retain the newly generated logs separately.
- [ ] Review the public repository once uploaded; confirm all files render and no private paths, credentials, or personal information are present.
- [ ] Create the Git tag `v0.1.0` only after the uploaded commit has passed the checks below.

## Local validation commands

Run from the repository root:

```bash
sha256sum -c results/SHA256SUMS
bash scripts/verify_logs.sh results/raw
mkdir -p build
g++ -O3 -march=native -std=c++17 -DNDEBUG src/dynamic_v2.cpp -o build/dynamic_v2
g++ -O3 -march=native -std=c++17 -DNDEBUG src/holdout_v2.cpp -o build/holdout_v2
./build/dynamic_v2 > /tmp/dynamic_smoke.log
./build/holdout_v2 > /tmp/holdout_smoke.log
grep -E '^(CHECK_SUMMARY|BENCH_SUMMARY)' /tmp/dynamic_smoke.log
grep -E '^(CHECK_SUMMARY|BENCH_SUMMARY)' /tmp/holdout_smoke.log
```

Expected smoke-test summaries:

- Dynamic: `groups=224`, `failures=0`, `rows=224`, `repeats=7`.
- Held-out: `groups=112`, `failures=0`, `rows=112`, `repeats=7`.
- Maximum voltage error observed in the archived logs: `4.4408920985e-16`.

To rerun the full archived design (three process runs per executable):

```bash
bash scripts/run_all.sh
```

This takes longer than a smoke test. It writes to `results/reproduced/` and does not overwrite `results/raw/`.

## GitHub Release fields

- **Tag:** `v0.1.0`
- **Release title:** `v0.1.0 — Initial reproducible experiment archive`
- **Release description:** Use [`release_notes_v0.1.0.md`](release_notes_v0.1.0.md).
- **Pre-release:** No, provided all checks above pass on the uploaded commit.
- **Assets:** Attach the source archive only if the GitHub-generated source archives are insufficient for the intended distribution. Keep the raw logs and SHA-256 manifest in the repository either way.

## Suggested publication sequence

1. Create the public repository with the identity above.
2. Upload/push the reviewed source tree.
3. Verify the README, source files, logs, and license on GitHub.
4. Re-run the checksum and smoke-test commands against a fresh clone.
5. Create tag `v0.1.0` and publish the release notes.
6. Publish the blog post, linking to the exact release/tag rather than a moving branch.

Do not describe the 11.3% observation as a general speedup. The comparison uses a per-configuration retrospective `min(FULL, LAZY)` oracle and the adaptive policy was selected after examining the same held-out set.
