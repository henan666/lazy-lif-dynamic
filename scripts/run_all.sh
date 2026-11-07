#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build results/reproduced
CXX="${CXX:-g++}"
CXXFLAGS="${CXXFLAGS:--O3 -march=native -std=c++17 -DNDEBUG}"
read -r -a FLAGS <<< "$CXXFLAGS"
"$CXX" "${FLAGS[@]}" src/dynamic_v2.cpp -o build/dynamic_v2
"$CXX" "${FLAGS[@]}" src/holdout_v2.cpp -o build/holdout_v2
for i in 1 2 3; do
  echo "[dynamic] process $i/3"
  ./build/dynamic_v2 > "results/reproduced/dynamic_run${i}.log"
  echo "[holdout] process $i/3"
  ./build/holdout_v2 > "results/reproduced/holdout_run${i}.log"
done
printf '\nReproduced logs written to results/reproduced/\n'
