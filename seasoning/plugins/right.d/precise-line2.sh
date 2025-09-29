#!/usr/bin/env bash
set -euo pipefail; LC_TIME=C
tz="$(date '+%Z')"; off="$(date '+%z')"; doy="$(date '+%-j')"; wk="$(date '+%-V')"; mon="$(date '+%m')"
printf "%s(%s) d%s w%s m%s\n" "$tz" "$off" "$doy" "$wk" "$mon"
