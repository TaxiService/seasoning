#!/usr/bin/env bash
# sextants clock with modes: discrete (default) | block | smooth
set -o pipefail; LC_ALL=C.UTF-8

SB_CELLS=${SB_CELLS:-30}
SB_DIVS=${SB_DIVS:-6}

BASE=$((0x1CE50))  # Unicode Sextants base
cap_l="│"; cap_r="│"; sep_mid="│"; sep_other="╵"

# ---- read mode via ctl-mode (per-output, per-plugin) ----
PLUGIN_ID="30-barclock-sextants"
OUT="${WAYBAR_OUTPUT_NAME:-$("/usr/bin/seasoning" which-output 2>/dev/null || echo default)}"
if mode_num=$(/usr/lib/seasoning/ctl-mode get "$OUT" "$PLUGIN_ID" 2>/dev/null); then
  case $mode_num in
    0) SBAR_HOURS="${SBAR_HOURS:-discrete}" ;;
    1) SBAR_HOURS=block ;;
    2) SBAR_HOURS=smooth ;;
  esac
fi
SBAR_HOURS=${SBAR_HOURS:-discrete}

# ---- glyph + bits helpers (kept minimal, UTF-8 via %b \U) ----
glyph(){ local m=$1; (( m==0 )) && { printf ' '; return; }; printf -v esc '\\U%08X' $((BASE+m)); printf '%b' "$esc"; }
bits_top(){ local idx=$1 col=$2 v=0; (( idx>col )) && v=$((v|1)); (( idx>col+1 )) && v=$((v|2)); printf '%d' "$v"; }
bits_mid(){ local idx=$1 col=$2 v=0; (( idx>col )) && v=$((v|4)); (( idx>col+1 )) && v=$((v|8)); printf '%d' "$v"; }

# hours: 0..11 mapped to 12 slots (5 half-cells each)
bits_bot_smooth(){ local h=$1 m=$2 col=$3 v=0; local idx=$(( (h%12)*5 + m/12 )); (( idx>col )) && v=$((v|16)); (( idx>col+1 )) && v=$((v|32)); printf '%d' "$v"; }
# motif 01110 within each 5-subcolumn hour
bits_bot_discrete(){ local h=$1 col=$2 v=0; local h12=$(( h%12 ))
  local slotL=$(( col/5 )); local posL=$(( col%5 ))
  local slotR=$(( (col+1)/5 )); local posR=$(( (col+1)%5 ))
  [[ $slotL -lt $h12 && $posL -ge 1 && $posL -le 3 ]] && v=$((v|16))
  [[ $slotR -lt $h12 && $posR -ge 1 && $posR -le 3 ]] && v=$((v|32))
  printf '%d' "$v"
}
# solid blocks per hour
bits_bot_block(){ local h=$1 col=$2 v=0; local h12=$(( h%12 ))
  (( (col/5)   < h12 )) && v=$((v|16))
  (( ((col+1)/5) < h12 )) && v=$((v|32))
  printf '%d' "$v"
}

render_line(){
  local s=$1 m=$2 h=$3
  local out="" i col mask bt bm bb
  for ((i=0;i<SB_CELLS;i++)); do
    col=$((i*2))
    bt=$(bits_top "$s" "$col")
    bm=$(bits_mid "$m" "$col")
    case "$SBAR_HOURS" in
      smooth) bb=$(bits_bot_smooth "$h" "$m" "$col") ;;
      block)  bb=$(bits_bot_block  "$h"           "$col") ;;
      *)      bb=$(bits_bot_discrete "$h"         "$col") ;;
    esac
    mask=$(( bt | bm | bb ))
    out+=$(glyph "$mask")
  done
  local step=$(( SB_CELLS / SB_DIVS ))
  local mid=$(( SB_CELLS / 2 ))
  local i part line="$cap_l"
  for ((i=0;i<SB_DIVS;i++)); do
    part="${out:i*step:step}"
    line+="$part"
    if (( i < SB_DIVS-1 )); then
      (( (i+1)*step == mid )) && line+="$sep_mid" || line+="$sep_other"
    fi
  done
  line+="$cap_r"
  printf '%s\n' "$line"
}

main(){
  local H M S; read -r H M S < <(date '+%H %M %S')
  H=$((10#$H)); M=$((10#$M)); S=$((10#$S))
  render_line "$S" "$M" "$H"
}
main
