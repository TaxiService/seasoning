#!/usr/bin/env bash
set -euo pipefail
YEAR_OFFSET=${YEAR_OFFSET:-10000}  # comment to disable +10000
m=$((10#$(date +%m))); idx=$(( m % 12 )); part_idx=$(( idx % 3 )); season_idx=$(( idx / 3 ))
case "$part_idx" in 0) part="early ";; 1) part="mid";; 2) part="late ";; esac
seasons=(winter spring summer autumn); season="${seasons[$season_idx]}"
printf "%s%s %d\n" "$part" "$season" $((10#$(date +%Y) + YEAR_OFFSET))
