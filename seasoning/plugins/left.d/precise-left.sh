# =====================================================================
# /usr/share/seasoning/plugins/left.d/precise-left.sh
# Modes: long | iso
# =====================================================================
#!/usr/bin/env bash
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" long iso; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/left.precise-left.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-long}"

case "$MODE" in
  long) date '+%a %B %d %Y' ;;
  iso)  date '+%F' ;;
  *)    date '+%a %B %d %Y' ;;
esac
