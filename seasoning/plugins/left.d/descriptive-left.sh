# =====================================================================
# /usr/share/seasoning/plugins/left.d/descriptive-left.sh
# Modes: words | 1st | noord
# =====================================================================
#!/usr/bin/env bash
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" words 1st noord; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/left.descriptive-left.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-words}"

m=$(date +%-m); d=$(date +%-d); LEAP=""
if [[ $m -eq 2 && $d -eq 29 ]]; then LEAP="!"; fi

dow=$(date +%A | tr '[:upper:]' '[:lower:]')
H=$((10#$(date +%H)))
case "$H" in
  0|1|2|3|4|5)  tod="night" ;;
  6|7|8|9|10|11) tod="morning" ;;
  12|13|14|15|16|17) tod="afternoon" ;;
  *)            tod="evening" ;;
esac

dom=$((10#$(date +%d)))
nth=$(( (dom-1)/7 + 1 ))
ord_word(){ case "$1" in 1)echo first;;2)echo second;;3)echo third;;4)echo fourth;;5)echo fifth;;*)echo "$1";; esac; }
ord_short(){ case "$1" in 1)echo 1st;;2)echo 2nd;;3)echo 3rd;;*)echo "${1}th";; esac; }

case "$MODE" in
  words) printf "%s %s %s%s\n" "$(ord_word "$nth")" "$dow" "$tod" "$LEAP" ;;
  1st)   printf "%s %s %s%s\n" "$(ord_short "$nth")" "$dow" "$tod" "$LEAP" ;;
  noord) printf "%s %s%s\n" "$dow" "$tod" "$LEAP" ;;
  *)     printf "%s %s %s%s\n" "$(ord_word "$nth")" "$dow" "$tod" "$LEAP" ;;
esac
