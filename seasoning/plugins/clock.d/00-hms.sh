# /usr/share/seasoning/plugins/clock.d/00-hms.sh
#!/usr/bin/env bash
set -euo pipefail
H=$(date +%H); M=$(date +%M); S=$(date +%S)
if ((10#$S % 2)); then COL="·"; else COL=":"; fi   # blink the separator
printf '%s%s%s\n' "$H" "$COL" "$M"
