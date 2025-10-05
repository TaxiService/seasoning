#!/usr/bin/env bash
# modes: 0=dow+timeofday  1=ordinal words  2=ordinal 1st/2nd/...
set -o pipefail; LC_ALL=C

OUT="${WAYBAR_OUTPUT_NAME:-$("/usr/bin/seasoning" which-output 2>/dev/null || echo default)}"
ID="descriptive-left"
mode=$(/usr/lib/seasoning/ctl-mode get "$OUT" "$ID" 2>/dev/null || echo 0)

dow=$(LC_ALL=C date +%A | tr '[:upper:]' '[:lower:]')
H=$(date +%H); h=$((10#$H))
if   ((h<6));  then tod=night
elif ((h<12)); then tod=morning
elif ((h<18)); then tod=afternoon
else               tod=evening
fi

ord_words=(zero first second third fourth fifth sixth seventh eighth ninth tenth eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth nineteenth twentieth twenty-first twenty-second twenty-third twenty-fourth twenty-fifth twenty-sixth twenty-seventh twenty-eighth twenty-ninth thirtieth thirty-first)
n=$((10#$(date +%d)))
ord_sup(){ local n=$1 s; case $((n%100)) in 11|12|13) s=th;; *) case $((n%10)) in 1)s=st;;2)s=nd;;3)s=rd;;*)s=th;; esac;; esac; printf '%d%s' "$n" "$s"; }

case "$mode" in
  1) printf '%s %s\n' "${ord_words[$n]}" "$tod" ;;
  2) printf '%s %s\n' "$(ord_sup "$n")" "$tod" ;;
  *) printf '%s %s\n' "$dow" "$tod" ;;
esac
