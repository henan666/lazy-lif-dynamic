#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-results/raw}"
shopt -s nullglob
files=("$DIR"/*.log)
if ((${#files[@]} == 0)); then echo "No .log files found in $DIR" >&2; exit 2; fi
for f in "${files[@]}"; do
  echo "== $f =="
  grep '^CHECK_SUMMARY' "$f"
  grep '^BENCH_SUMMARY' "$f"
  grep -q 'failures=0' <(grep '^CHECK_SUMMARY' "$f") || { echo "correctness failure in $f" >&2; exit 1; }
  grep -q 'repeats=7' <(grep '^BENCH_SUMMARY' "$f") || { echo "unexpected repeat count in $f" >&2; exit 1; }
done
