#!/usr/bin/env bash
set -euo pipefail
iters="${1:-200}"
py="${2:-/usr/share/seasoning/plugins/clock.d/30-sextant.py}"
sh="${3:-/usr/share/seasoning/plugins/clock.d/31-sextant.sh}"
bench_one(){ local cmd="$1" n="$2" t0 t1 sum=0 i
  for((i=0;i<n;i++));do t0=$(date +%s%N); bash -lc "$cmd" >/dev/null; t1=$(date +%s%N); sum=$((sum+(t1-t0))); done
  awk -v ns="$((sum/n))" -v cmd="$cmd" 'BEGIN{printf "%s\tavg %.3f ms\n", cmd, ns/1e6}'
}
bench_one "$py" "$iters"; bench_one "$sh" "$iters"
