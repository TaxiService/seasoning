# /usr/share/seasoning/plugins/clock.d/05-test-modes.sh
#!/usr/bin/env bash
set -euo pipefail

OUT="$(/usr/bin/seasoning which-output 2>/dev/null || echo default)"
CACHE="$HOME/.cache/seasoning/$OUT"
SELF="$(basename "$0")"

# prefer per-plugin mode; fallback to legacy global
MODE="$(cat "$CACHE/mode.$SELF.state" 2>/dev/null || cat "$CACHE/clock.mode" 2>/dev/null || echo 0)"
MODE=$(( MODE % 3 ))

case "$MODE" in
  0) printf '{"text":"A","class":"clock--test-a"}\n' ;;
  1) printf '{"text":"B","class":"clock--test-b"}\n' ;;
  2) printf '{"text":"C","class":"clock--test-c"}\n' ;;
esac
