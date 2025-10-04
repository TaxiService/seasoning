# =====================================================================
# /usr/share/seasoning/plugins/right.d/precise-right.sh
# Modes: metrics | tzonly
# metrics → "CEST(+0200) d256 w35 m09"
# tzonly  → "CEST(+0200)"
# =====================================================================
#!/usr/bin/env bash
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" metrics tzonly; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/right.precise-right.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-metrics}"

TZNAME=$(date +%Z)
OFFSET=$(date +%z)  # +hhmm
case "$MODE" in
  tzonly)
    printf "%s(%s)\n" "$TZNAME" "$OFFSET"
    ;;
  metrics|*)
    doy=$(date +%j)    # 001..366
    wk=$(date +%V)     # ISO week 01..53
    mon=$(date +%m)    # 01..12
    printf "%s(%s) d%02d w%02d m%02d\n" "$TZNAME" "$OFFSET" "$((10#$doy))" "$((10#$wk))" "$((10#$mon))"
    ;;
esac
