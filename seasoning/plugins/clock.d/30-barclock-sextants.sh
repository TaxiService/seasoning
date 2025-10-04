#!/usr/bin/env bash
# /usr/share/seasoning/plugins/clock.d/30-barclock-sextants.sh
# Modes: discrete | block | smooth
set -o pipefail
LC_ALL=C.UTF-8

SB_CELLS=${SB_CELLS:-30}
SB_DIVS=${SB_DIVS:-6}
BASE=$((0x1CE50))
cap_l="│"; cap_r="│"; sep_mid="│"; sep_other="╵"

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
# args: --output OUT | --mode NAME | --list-modes
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" discrete block smooth; exit 0;;
    *) shift;;
  esac
done

# per-output mode state
state="$HOME/.cache/seasoning/$OUT/clock.barclock-sextants.mode"
if [[ -z "$MODE" && -f "$state" ]]; then MODE="$(<"$state")"; fi
MODE="${MODE:-${SBAR_HOURS:-discrete}}"

glyph() {
  local m=$1
  if (( m == 0 )); then printf ' '; return; fi
  printf -v esc '\\U%08X' $((BASE + m))
  printf '%b' "$esc"
}
bits_top() { local idx=$1 col=$2 v=0; (( idx > col )) && v=$((v|1)); (( idx > col+1 )) && v=$((v|2)); printf '%d' "$v"; }
bits_mid() { local idx=$1 col=$2 v=0; (( idx > col )) && v=$((v|4)); (( idx > col+1 )) && v=$((v|8)); printf '%d' "$v"; }
bits_bot_smooth() { local h=$1 m=$2 col=$3 v=0; local idx=$(( (h%12)*5 + m/12 )); (( idx > col )) && v=$((v|16)); (( idx > col+1 )) && v=$((v|32)); printf '%d' "$v"; }
bits_bot_discrete(){
  local h=$1 col=$2 v=0 h12=$(( h % 12 ))
  local slotL=$(( col/5 )) posL=$(( col%5 ))
  local slotR=$(( (col+1)/5 )) posR=$(( (col+1)%5 ))
  (( slotL < h12 )) && { [[ $posL =~ ^[123]$ ]] && v=$((v|16)); }
  (( slotR < h12 )) && { [[ $posR =~ ^[123]$ ]] && v=$((v|32)); }
  printf '%d' "$v"
}
bits_bot_block(){
  local h=$1 col=$2 v=0 h12=$(( h % 12 ))
  (( (col/5)     < h12 )) && v=$((v|16))
  (( ((col+1)/5) < h12 )) && v=$((v|32))
  printf '%d' "$v"
}

main() {
  local H M S; read -r H M S < <(date '+%H %M %S')
  H=$((10#$H)); M=$((10#$M)); S=$((10#$S))
  local step=$(( SB_CELLS / SB_DIVS )); local center_cut=$(( SB_CELLS / 2 ))

  printf '%s' "$cap_l"
  for ((cell=0; cell<SB_CELLS; cell++)); do
    col=$((cell*2))
    t=$(bits_top "$S" "$col")
    m=$(bits_mid "$M" "$col")
    case "$MODE" in
      smooth) b=$(bits_bot_smooth "$H" "$M" "$col") ;;
      block)  b=$(bits_bot_block  "$H"       "$col") ;;
      *)      b=$(bits_bot_discrete "$H"     "$col") ;;
    esac
    glyph $(( t | m | b ))
    cut=$((cell+1))
    if (( cut < SB_CELLS && (cut % step) == 0 )); then
      if (( cut == center_cut )); then printf '%s' "$sep_mid"; else printf '%s' "$sep_other"; fi
    fi
  done
  printf '%s\n' "$cap_r"
}
main
