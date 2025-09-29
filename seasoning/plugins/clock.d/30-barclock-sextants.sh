# /usr/share/seasoning/plugins/clock.d/30-barclock-sextants.sh
#!/usr/bin/env bash
# ASCII-only for stability; we’ll re-enable sextants later.
set -o pipefail

CELLS=${CELLS:-30}
DIVS=${DIVS:-6}
LEFT_CAP=${LEFT_CAP:-"|"}
RIGHT_CAP=${RIGHT_CAP:-"|"}
MID_SEP=${MID_SEP:-"|"}
OTHER_SEP=${OTHER_SEP:-"'"}

hour_to_idx(){ local h=$1 m=$2; printf "%d" $(( (h%12)*5 + (m/12) )); }

build_cells_ascii() {
  local t_idx=$1 m_idx=$2 b_idx=$3
  local out="" i col
  for ((i=0;i<CELLS;i++)); do
    col=$(( i*2 ))
    if (( t_idx>col || t_idx>col+1 || m_idx>col || m_idx>col+1 || b_idx>col || b_idx>col+1 )); then
      out+="#"
    else
      out+=" "
    fi
  done
  printf "%s" "$out"
}

line_with_dividers() {
  local cells="$1" L=${#cells}
  (( L==0 )) && { printf "%s%s" "$LEFT_CAP" "$RIGHT_CAP"; return; }
  local -a cuts=(0); for ((k=1;k<DIVS;k++)); do cuts+=( $(((k*L)/DIVS)) ); done; cuts+=("$L")
  local out="$LEFT_CAP" mid=$((L/2))
  for ((k=0;k<${#cuts[@]}-1;k++)); do
    local a=${cuts[k]} b=${cuts[k+1]}
    out+="${cells:a:b-a}"
    if (( k<${#cuts[@]}-2 )); then
      local cut=${cuts[k+1]}
      if (( cut==mid )); then out+="$MID_SEP"; else out+="$OTHER_SEP"; fi
    fi
  done
  out+="$RIGHT_CAP"
  printf "%s\n" "$out"
}

H=$(date +%H); M=$(date +%M); S=$(date +%S)
h=$((10#$H)); m=$((10#$M)); s=$((10#$S))
cells="$(build_cells_ascii "$s" "$m" "$(hour_to_idx "$h" "$m")")" || cells=""
line="$(line_with_dividers "${cells:-}")" || line="|?|"
[[ -n "$line" ]] || line="|?|"
printf "%s\n" "$line"
exit 0

# Ensure exec + LF
sudo chmod +x /usr/share/seasoning/plugins/clock.d/30-barclock-sextants.sh
sudo sed -i 's/\r$//' /usr/share/seasoning/plugins/clock.d/30-barclock-sextants.sh

# Waybar clock block (must be EXACTLY this while using the ticker)
# ~/.config/waybar/config.jsonc
{
  "custom/seasoning-clock": {
    "exec": "/usr/bin/seasoning run clock",
    "return-type": "json",
    "interval": 0,
    "signal": 6,
    "on-click": "/usr/bin/seasoning ctl clock cycle $(/usr/bin/seasoning which-output); /usr/bin/seasoning signal 6",
    "tooltip": false
  }
}
