#!/usr/bin/env bash
set -o pipefail
m=$(date +%-m); d=$(date +%-d)
if [ "$m" -eq 2 ] && [ "$d" -eq 29 ]; then LEAP_BANG="!"; else LEAP_BANG=""; fi
dow="$(date +%A|tr '[:upper:]' '[:lower:]')";
h=$((10#$(date +%H)))
case "$h" in  0| 1| 2| 3| 4| 5) tod="night";;
			  6| 7| 8| 9|10|11) tod="morning";;
			 12|13|14|15|16|17) tod="afternoon";;
			 *) tod="evening";;
esac
n=$(( (10#$d-1)/7 + 1 ));
case "$n" in 1)s="st";;
			 2)s="nd";;
			 3)s="rd";;
			 *)s="th";;
esac
printf "%d%s %s %s%s\n" "$n" "$s" "$dow" "$tod" "$LEAP_BANG"