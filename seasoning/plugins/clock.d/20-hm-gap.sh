#!/usr/bin/env bash
set -euo pipefail
H=$(date +%H); M=$(date +%M); S=$(date +%S); b=$((10#$S%2))
((b)) && printf "%s %s\n" "$H" "$M" || printf "%s:%s\n" "$H" "$M"
