# =====================================================================
# /usr/share/seasoning/plugins/right.d/descriptive-right.sh
# Modes: dfyear | dfyear-no10k  (Dwarf Fortress-style season + year)
# YEAR_OFFSET default 10000; set to 0 to disable.
# =====================================================================
#!/usr/bin/env bash
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" dfyear dfyear-no10k; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/right.descriptive-right.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-dfyear}"

y=$((10#$(date +%Y)))
offset=${YEAR_OFFSET:-10000}
[[ "$MODE" == "dfyear-no10k" ]] && offset=0
y=$((y+offset))

m=$((10#$(date +%m)))
part=""; season=""
case "$m" in
  12) part="early "; season="winter";;
  1)  part="mid";    season="winter";;
  2)  part=" late";  season="winter";;
  3)  part="early "; season="spring";;
  4)  part="mid";    season="spring";;
  5)  part=" late";  season="spring";;
  6)  part="early "; season="summer";;
  7)  part="mid";    season="summer";;
  8)  part=" late";  season="summer";;
  9)  part="early "; season="autumn";;
  10) part="mid";    season="autumn";;
  11) part=" late";  season="autumn";;
esac

# enforce spacing style: 'early ' and ' late' have spaces; 'mid' flush
label="$part$season"
label="${label/ mid/mid}"   # keep 'mid' flush if shell expands weird spacing

printf "%s %d\n" "$label" "$y"
