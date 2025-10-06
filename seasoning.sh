#!/usr/bin/env bash
# seasoning — single CLI for Waybar modules (mid clock + side pairs)
set -euo pipefail
trap '' PIPE

# --- dirs ---
SEAS_USER_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/seasoning"
SEAS_USER_PLUG="$SEAS_USER_CFG/plugins"
SEAS_SYS="/usr/share/seasoning"
SEAS_SYS_PLUG="$SEAS_SYS/plugins"
SEAS_CFG_FILE_USER="$SEAS_USER_CFG/config.json"
SEAS_CFG_FILE_SYS="$SEAS_SYS/config.json"
SEAS_CACHE="${SEASONING_CACHE:-$HOME/.cache/seasoning}"

# --- signals (overridable by config.json) ---
SIG_MID=6
SIG_SIDES=5

usage() {
  cat >&2 <<'USAGE'
usage:
  seasoning run mid
  seasoning run side {left|right}
  seasoning ctl mid   {cycle|prev|set N|mode-next}   [--output NAME]
  seasoning ctl sides {cycle|prev|set N|mode-next}   [--which left|right] [--output NAME]
  seasoning which-output
  seasoning doctor
USAGE
  exit 2
}

# ---------- helpers ----------
which_output() {
  if [[ -n "${WAYBAR_OUTPUT_NAME-}" ]]; then printf '%s\n' "$WAYBAR_OUTPUT_NAME"; return; fi
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '[.[]|select(.focused==true or .active==true)][0].name // empty' | sed -n '1p' && return 0 || true
  fi
  if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    swaymsg -r -t get_outputs | jq -r '[.[]|select(.focused==true)][0].name // empty' | sed -n '1p' && return 0 || true
  fi
  printf 'default\n'
}

send_signal(){ local n="${1:-6}" sig="RTMIN+$n"; pkill -x -"$sig" waybar 2>/dev/null || true; }

canon(){ local b="${1##*/}"; printf '%s\n' "$b"; }

ensure_cache(){ mkdir -p "$SEAS_CACHE/$1"; }

f_state(){ printf '%s/%s.state' "$SEAS_CACHE/$1" "$2"; }             # ($out, key) → path
f_mode(){  printf '%s/mode.%s.state' "$SEAS_CACHE/$1" "$(canon "$2")"; } # per-plugin mode

read_int(){ local v; v="$(cat "$1" 2>/dev/null || echo 0)"; [[ "$v" =~ ^[0-9]+$ ]] || v=0; printf '%s\n' "$v"; }
write_int(){ local p="$1" v="$2"; mkdir -p "$(dirname "$p")"; printf '%s' "$v" >"$p".tmp && mv -f "$p".tmp "$p"; }

# ---------- config ----------
cfg_file(){ [[ -f "$SEAS_CFG_FILE_USER" ]] && printf '%s\n' "$SEAS_CFG_FILE_USER" || printf '%s\n' "$SEAS_CFG_FILE_SYS"; }
cfg_has(){ jq -e "$1" "$(cfg_file)" >/dev/null 2>&1; }
cfg_get(){ jq -r "$1" "$(cfg_file)"; }

load_config() {
  if ! command -v jq >/dev/null 2>&1; then echo '{"text":"[seasoning:jq-missing]"}'; exit 0; fi
  local f; f="$(cfg_file)"; [[ -f "$f" ]] || { echo '{"text":"[seasoning:config-missing]"}'; exit 0; }
  # signals
  SIG_MID=$(jq -r '.signals.mid // 6' "$f")
  SIG_SIDES=$(jq -r '.signals.sides // 5' "$f")
}

# ---------- discovery ----------
resolve_plugin_path(){
  local name="$1"
  if [[ -x "$SEAS_USER_PLUG/$name" ]]; then printf '%s\n' "$SEAS_USER_PLUG/$name"; return; fi
  if [[ -x "$SEAS_SYS_PLUG/$name" ]];  then printf '%s\n' "$SEAS_SYS_PLUG/$name";  return; fi
  return 1
}

list_mid(){
  cfg_get '.mid.plugins[]?' 2>/dev/null || true
}

pairs_len(){
  cfg_get '.sides.pairs | length' 2>/dev/null || echo 0
}
pair_names_at(){
  local i="$1"
  cfg_get ".sides.pairs[$i] | @tsv" 2>/dev/null
}

mode_count_for(){
  local name="$1" which="$2" # mid|sides
  if [[ "$which" == "mid" ]]; then
    cfg_get ".mid.mode_count[\"$name\"] // 1" 2>/dev/null || echo 1
  else
    cfg_get ".sides.mode_count[\"$name\"] // 1" 2>/dev/null || echo 1
  fi
}

# ---------- runners ----------
run_mid(){
  load_config
  local out; out="$(which_output)"; ensure_cache "$out"
  mapfile -t arr < <(list_mid)
  local n="${#arr[@]}"; (( n>0 )) || { echo '{"text":"[seasoning:mid:no-plugins]"}'; exit 0; }
  local idx; idx="$(read_int "$(f_state "$out" mid)")"; (( idx%=n ))
  local name="${arr[$idx]}"
  local p; p="$(resolve_plugin_path "$name")" || { echo '{"text":"[seasoning:mid:bad-plugin]"}'; exit 0; }
  local modes; modes="$(mode_count_for "$name" mid)"
  local mfile; mfile="$(f_mode "$out" "$name")"
  local mm; mm="$(read_int "$mfile")"; (( modes>0 )) && (( mm%=modes ))
  SEASONING_MODE="$mm" "$p" 2>/dev/null || echo '{"text":"[seasoning:mid:err]"}'
}

run_side(){
  load_config
  local side="${1:-left}"; [[ "$side" =~ ^(left|right)$ ]] || side="left"
  local out; out="$(which_output)"; ensure_cache "$out"
  local n; n="$(pairs_len)"; (( n>0 )) || { echo "[seasoning:sides:empty]"; exit 0; }
  local idx; idx="$(read_int "$(f_state "$out" pair)")"; (( idx%=n ))
  local lr; lr="$(pair_names_at "$idx")"
  local L="${lr%%$'\t'*}"; local R="${lr#*$'\t'}"
  local target="$L"; [[ "$side" == "right" ]] && target="$R"
  local p; p="$(resolve_plugin_path "$target")" || { echo "[seasoning:$side:bad-plugin]"; exit 0; }
  local modes; modes="$(mode_count_for "$target" sides)"
  local mfile; mfile="$(f_mode "$out" "$target")"
  local mm; mm="$(read_int "$mfile")"; (( modes>0 )) && (( mm%=modes ))
  SEASONING_MODE="$mm" "$p" 2>/dev/null || echo "[seasoning:$side:err]"
}

# ---------- control ----------
ctl_mid(){
  load_config
  local action="${1:-cycle}"; shift || true
  local out=""; while [[ $# -gt 0 ]]; do case "$1" in --output) out="$2"; shift 2;; *) break;; esac; done
  [[ -n "$out" ]] || out="$(which_output)"; ensure_cache "$out"
  mapfile -t arr < <(list_mid); local n="${#arr[@]}"; (( n>0 )) || exit 0
  local st; st="$(f_state "$out" mid)"
  case "$action" in
    prev)  write_int "$st" $(( ( $(read_int "$st") - 1 + n) % n )) ;;
    cycle) write_int "$st" $(( ( $(read_int "$st") + 1 ) % n )) ;;
    set)   local v="${1:-0}"; write_int "$st" $(( v % n )) ;;
    mode-next)
      local name="${arr[$(read_int "$st")]}"
      local mfile; mfile="$(f_mode "$out" "$name")"
      local modes; modes="$(mode_count_for "$name" mid)"
      write_int "$mfile" $(( ( $(read_int "$mfile") + 1 ) % (modes>0?modes:1) ))
      send_signal "$SIG_MID"; return 0
      ;;
    *) usage ;;
  esac
  send_signal "$SIG_MID"
}

ctl_sides(){
  load_config
  local action="${1:-cycle}"; shift || true
  local which=""; local out=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --which)  which="$2"; shift 2;;
      --output) out="$2";  shift 2;;
      *) break;;
    esac
  done
  [[ -n "$out" ]] || out="$(which_output)"; ensure_cache "$out"
  local n; n="$(pairs_len)"; (( n>0 )) || exit 0
  local st; st="$(f_state "$out" pair)"
  case "$action" in
    prev)  write_int "$st" $(( ( $(read_int "$st") - 1 + n) % n )) ;;
    cycle) write_int "$st" $(( ( $(read_int "$st") + 1 ) % n )) ;;
    set)   local v="${1:-0}"; write_int "$st" $(( v % n )) ;;
    mode-next)
      [[ "$which" =~ ^(left|right)$ ]] || which="left"
      local idx; idx="$(read_int "$st")"; (( idx%=n ))
      local lr; lr="$(pair_names_at "$idx")"
      local L="${lr%%$'\t'*}"; local R="${lr#*$'\t'}"
      local name="$L"; [[ "$which" == "right" ]] && name="$R"
      local mfile; mfile="$(f_mode "$out" "$name")"
      local modes; modes="$(mode_count_for "$name" sides)"
      write_int "$mfile" $(( ( $(read_int "$mfile") + 1 ) % (modes>0?modes:1) ))
      send_signal "$SIG_SIDES"; return 0
      ;;
    *) usage ;;
  esac
  send_signal "$SIG_SIDES"
}

doctor(){
  load_config
  echo "== seasoning doctor =="
  echo "output: $(which_output)"
  echo "signals: mid=$SIG_MID sides=$SIG_SIDES"
  echo "mid plugins:"; list_mid | nl -ba
  echo "pairs:"; cfg_get '.sides.pairs[] | join(" | ")'
}

# ---------- main ----------
case "${1:-}" in
  run)
    case "${2:-}" in
      mid)  run_mid ;;
      side) run_side "${3:-left}" ;;
      *) usage ;;
    esac
    ;;
  ctl)
    case "${2:-}" in
      mid)   shift 2; ctl_mid   "$@" ;;
      sides) shift 2; ctl_sides "$@" ;;
      *) usage ;;
    esac
    ;;
  which-output) which_output ;;
  doctor) doctor ;;
  *) usage ;;
esac
