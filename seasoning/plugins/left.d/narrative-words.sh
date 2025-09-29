#!/usr/bin/env bash
set -euo pipefail; LC_TIME=C
d="$(date +%d)"; m="$(date +%m)"; dow="$(date +%A|tr '[:upper:]' '[:lower:]')"; h=$((10#$(date +%H)))
case "$h" in 0|1|2|3|4|5) tod="night";; 6|7|8|9|10|11) tod="morning";; 12|13|14|15|16|17) tod="afternoon";; *) tod="evening";; esac
ords=(first second third fourth fifth); ord="${ords[$(((10#$d-1)/7))]}"; excl=""; [[ "$m"=="02" && "$d"=="29" ]]&&excl="!"
printf "%s %s %s%s\n" "$ord" "$dow" "$tod" "$excl"
