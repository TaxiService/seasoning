#!/usr/bin/env bash
set -euo pipefail

OUT="$(/usr/bin/seasoning which-output 2>/dev/null || echo default)"
CACHE="$HOME/.cache/seasoning/$OUT"
SELF="$(basename "$0")"

# prefer per-plugin mode; fallback to legacy global clock.mode
MODE="$(cat "$CACHE/mode.$SELF.state" 2>/dev/null || cat "$CACHE/clock.mode" 2>/dev/null || echo 0)"
MODE=$(( MODE % 4 ))

H="$(date +%H)"; M="$(date +%M)"; S="$(date +%S)"
case "$MODE" in
  0) printf '{"text":"%s·%s","class":"clock--hms-m0"}\n' "$H" "$M" ;;
  1) printf '{"text":"%s:%s","class":"clock--hms-m1"}\n' "$H" "$M" ;;
  2) printf '{"text":"%s %s","class":"clock--hms-m2"}\n' "$H" "$M" ;;
  3) printf '{"text":"%s:%s:%s","class":"clock--hms-m3"}\n' "$H" "$M" "$S" ;;
esac
