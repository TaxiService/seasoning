#!/usr/bin/env bash
set -euo pipefail

OUT="$(/usr/bin/seasoning which-output 2>/dev/null || echo default)"
CACHE="$HOME/.cache/seasoning/$OUT"
SELF="$(basename "$0")"

# prefer per-plugin mode; fallback to legacy global clock.mode
MODE="$(cat "$CACHE/mode.$SELF.state" 2>/dev/null || cat "$CACHE/clock.mode" 2>/dev/null || echo 0)"
MODE=$(( MODE % 4 ))

H="$(date +%H)"; M="$(date +%M)"; S="$(date +%S)"
case "$MODE" in
  0) printf '{"text":"%s·%s","class":"clock--hms-m0"}\n' "$H" "$M" ;;
  1) printf '{"text":"%s:%s","class":"clock--hms-m1"}\n' "$H" "$M" ;;
  2) printf '{"text":"%s %s","class":"clock--hms-m2"}\n' "$H" "$M" ;;
  3) printf '{"text":"%s:%s:%s","class":"clock--hms-m3"}\n' "$H" "$M" "$S" ;;
esac


# #!/usr/bin/env bash
# # Modes:
# # 0: H:M        (blink ":" every second using "·" as off)
# # 1: H·M        (static, no seconds)
# # 2: H:M:S      (static)
# # 3: H·M·S      (static)
# set -o pipefail

# # resolve output for per-output mode file
# out="${WAYBAR_OUTPUT_NAME:-$("/usr/bin/seasoning" which-output 2>/dev/null || echo default)}"
# mode_file="$HOME/.cache/seasoning/$out/clock.mode"
# mode=$(cat "$mode_file" 2>/dev/null || echo 0)

# H=$(date +%H)
# M=$(date +%M)
# S=$(date +%S)
# sec=$((10#$S))

# # helpers
# colon_blink() { (( sec % 2 )) && printf "·" || printf ":"; }

# text=""
# case "$mode" in
#   0) text="${H}$(colon_blink)${M}" ;;
#   1) text="${H}·${M}" ;;
#   2) text="${H}:${M}:${S}" ;;
#   3) text="${H}·${M}·${S}" ;;
#   *) text="${H}$(colon_blink)${M}" ;;  # fallback
# esac

# printf '{"text":"%s","class":"clock--hms-m%s"}\n' "$text" "$mode"
