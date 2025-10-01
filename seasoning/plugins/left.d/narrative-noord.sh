#!/usr/bin/env bash
set -o pipefail
m=$(date +%-m); d=$(date +%-d)
if [ "$m" -eq 2 ] && [ "$d" -eq 29 ]; then LEAP_BANG="!"; else LEAP_BANG=""; fi
set -euo pipefail; LC_TIME=C
d="$(date +%d)"; m="$(date +%m)"; dow="$(date +%A|tr '[:upper:]' '[:lower:]')"; h=$((10#$(date +%H)))
case "$h" in  0| 1| 2| 3| 4| 5) tod="night";;
			  6| 7| 8| 9|10|11) tod="morning";;
			 12|13|14|15|16|17) tod="afternoon";;
			 *) tod="evening";;
esac
printf '%s %s%s\n' "$dow" "$tod" "$LEAP_BANG"