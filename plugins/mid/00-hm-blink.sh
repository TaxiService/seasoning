#!/usr/bin/env bash
set -euo pipefail
H=$(date +%H); M=$(date +%M); S=$(date +%S)
((10#$S % 2)) && printf "%s.%s\n" "$H" "$M" || printf "%s:%s\n" "$H" "$M"
