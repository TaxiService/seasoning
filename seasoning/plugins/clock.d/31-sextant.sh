#!/usr/bin/env bash
set -euo pipefail
H=$(date +%H); M=$(date +%M); S=$(date +%S)
h=$((10#$H)); m=$((10#$M)); s=$((10#$S)); b=$((s%2))
hour_line(){ local w=24 out="" i; for((i=0;i<w;i++));do
  if(( i==(h%24) )); then out+="|"; elif(( i%6==0 )); then out+="·"; else out+=" "; fi
done; printf "%s\n" "$out"; }
bar_line(){ local pos="$1" w=60 out="" i; for((i=0;i<w;i++));do (( i<=pos ))&&out+="#"||out+=" "; done
for((i=0;i<w;i+=10));do out="${out:0:i}|${out:i+1}"; done; printf "%s\n" "$out"; }
if   (( s==0 )); then hour_line
elif (( b==1 )); then bar_line "$s"
else bar_line "$m"
fi
