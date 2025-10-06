#!/usr/bin/env bash
set -euo pipefail
mod="${1:?usage: ctl.sh {clock|pair} {cycle|prev|set N|mode-next} [--output OUT] }"; shift
act="${1:-cycle}"; shift || true

out="${WAYBAR_OUTPUT_NAME:-}"
[[ -z "$out" ]] && out="$(/usr/bin/seasoning which-output 2>/dev/null || true)"

args=(ctl "$mod")
case "$act" in
  mode-next) args+=(mode-next --output "$out") ;;
  set)       args+=(set --output "$out" "${1:-0}") ;;
  prev|cycle)args+=("$act" --output "$out") ;;
  *)         args+=(cycle --output "$out") ;;
esac

exec /usr/bin/seasoning "${args[@]}"
