#!/usr/bin/env bash
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" hm-blink hms hm-gap; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/clock.hms.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-hm-blink}"

H=$(date +%H) M=$(date +%M) S=$(date +%S)
sec=$((10#$S))

case "$MODE" in
  hm-blink)
    # blink every odd second to avoid 2 updates per tick
    if (( sec % 2 )); then printf "%s.%s\n" "$H" "$M"; else printf "%s:%s\n" "$H" "$M"; fi
    ;;
  hms)
    printf "%s:%s:%s\n" "$H" "$M" "$S"
    ;;
  hm-gap)
    # static H M (space instead of colon)
    printf "%s %s\n" "$H" "$M"
    ;;
  *) printf "%s:%s\n" "$H" "$M";;
esac
main
