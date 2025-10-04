# =====================================================================
# /usr/share/seasoning/plugins/left.d/descriptive.sh
# Modes: words | 1st | noord
# State file: ~/.cache/seasoning/<OUT>/left.descriptive.mode
# =====================================================================
#!/usr/bin/env bash
set -o pipefail
LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-${1:-}}"
# allow explicit --output OUT
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" "words" "1st" "noord"; exit 0;;
    --cycle-mode)
      OUT="${OUT:-default}"
      modes=(words 1st noord)
      st="$HOME/.cache/seasoning/$OUT/left.descriptive.mode"; mkdir -p "$(dirname "$st")"
      cur=""; [[ -f "$st" ]] && cur="$(<"$st")"
      idx=0; for i in "${!modes[@]}"; do [[ "${modes[$i]}" == "$cur" ]] && idx="$i"; done
      idx=$(( (idx+1) % ${#modes[@]} ))
      printf '%s' "${modes[$idx]}" > "$st"
      # do not print content; caller will re-render module
      exit 0;;
    *) shift;;
  esac
done

OUT="${OUT:-default}"
state="$HOME/.cache/seasoning/$OUT/left.descriptive.mode"
[[ -z "${MODE:-}" && -f "$state" ]] && MODE="$(<"$state")"
MODE="${MODE:-words}"

m=$(date +%-m); d=$(date +%-d)
LEAP_BANG=""
if [ "$m" -eq 2 ] && [ "$d" -eq 29 ]; then LEAP_BANG="!"; fi

dow_lc="$(date +%A | tr '[:upper:]' '[:lower:]')"
H=$((10#$(date +%H)))
case "$H" in
  0|1|2|3|4|5)  tod="night" ;;
  6|7|8|9|10|11) tod="morning" ;;
  12|13|14|15|16|17) tod="afternoon" ;;
  *)            tod="evening" ;;
esac

# nth <dow> of month (1..5)
day=$(date +%d); dom=$((10#$day))
nth=$(( ( (dom - 1) / 7 ) + 1 ))
ord_word(){ case "$1" in 1)echo first;;2)echo second;;3)echo third;;4)echo fourth;;5)echo fifth;;*)echo "$1";; esac; }
ord_short(){ case "$1" in 1)echo 1st;;2)echo 2nd;;3)echo 3rd;;*)echo "${1}th";; esac; }

case "$MODE" in
  words)  printf "%s %s %s%s\n"   "$(ord_word "$nth")" "$dow_lc" "$tod" "$LEAP_BANG" ;;
  1st)    printf "%s %s %s%s\n"   "$(ord_short "$nth")" "$dow_lc" "$tod" "$LEAP_BANG" ;;
  noord)  printf "%s %s%s\n"      "$dow_lc" "$tod" "$LEAP_BANG" ;;
  *)      printf "%s %s %s%s\n"   "$(ord_word "$nth")" "$dow_lc" "$tod" "$LEAP_BANG" ;;
esac
