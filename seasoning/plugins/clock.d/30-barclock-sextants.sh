# =====================================================================
# /usr/share/seasoning/plugins/clock.d/30-barclock-sextants.sh
# Modes: smooth | discrete | block
# =====================================================================
#!/usr/bin/env bash
set -o pipefail; LC_ALL=C.UTF-8

OUT="${WAYBAR_OUTPUT_NAME:-default}"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    --mode)   MODE="$2"; shift 2;;
    --list-modes) printf "%s\n" smooth discrete block; exit 0;;
    *) shift;;
  esac
done
st="$HOME/.cache/seasoning/$OUT/clock.barclock-sextants.mode"
[[ -z "$MODE" && -f "$st" ]] && MODE="$(<"$st")"
MODE="${MODE:-discrete}"

CELLS=${SB_CELLS:-30} DIVS=${SB_DIVS:-6}
BASE=$((0x1CE50)) cap_l="│" cap_r="│" sep_mid="│" sep_other="╵"

g() { local m=$1; ((m==0)) && { printf ' '; return; }; printf -v e '\\U%08X' $((BASE+m)); printf '%b' "$e"; }

bits_top(){ local idx=$1 b=$2 v=0; ((idx>b))&&v=$((v|1)); ((idx>b+1))&&v=$((v|2)); printf %d "$v"; }
bits_mid(){ local idx=$1 b=$2 v=0; ((idx>b))&&v=$((v|4)); ((idx>b+1))&&v=$((v|8)); printf %d "$v"; }

# hour bar modes
b_smooth(){ local h=$1 m=$2 b=$3 v=0 i=$(( (h%12)*5 + m/12 )); ((i>b))&&v=$((v|16)); ((i>b+1))&&v=$((v|32)); printf %d "$v"; }
b_discrete(){ # pattern 01110 for each hour block
  local h=$1 b=$2 v=0 h12=$((h%12))
  local Lblk=$(( b   /5 )) Lpos=$(( b   %5 ))
  local Rblk=$(( (b+1)/5 )) Rpos=$(( (b+1)%5 ))
  [[ $Lblk -lt $h12 && $Lpos -ge 1 && $Lpos -le 3 ]] && v=$((v|16))
  [[ $Rblk -lt $h12 && $Rpos -ge 1 && $Rpos -le 3 ]] && v=$((v|32))
  printf %d "$v"
}
b_block(){   # pattern 11111 for each completed hour block
  local h=$1 b=$2 v=0 h12=$((h%12))
  (( b   /5 < h12 )) && v=$((v|16))
  (((b+1)/5 < h12 )) && v=$((v|32))
  printf %d "$v"
}

H=$(date +%H); M=$(date +%M); S=$(date +%S)
H=$((10#$H)); M=$((10#$M)); S=$((10#$S))

printf '%s' "$cap_l"
step=$((CELLS/DIVS)) center=$((CELLS/2))
for ((c=0;c<CELLS;c++)); do
  b=$((c*2))
  t=$(bits_top "$S" "$b")
  m=$(bits_mid "$M" "$b")
  case "$MODE" in
    smooth) h=$(b_smooth "$H" "$M" "$b");;
    block)  h=$(b_block  "$H" "$b");;
    *)      h=$(b_discrete "$H" "$b");;
  esac
  g $((t|m|h))
  cut=$((c+1))
  if (( cut<CELLS && cut%step==0 )); then
    (( cut==center )) && printf '%s' "$sep_mid" || printf '%s' "$sep_other"
  fi
done
printf '%s\n' "$cap_r"
