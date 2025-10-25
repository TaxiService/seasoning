#!/usr/bin/env bash
# seasoning — minimal stable runner for Waybar custom modules (mid + sides)

set -o pipefail
trap '' PIPE

SEAS_PLUGINS="${SEAS_PLUGINS:-/usr/share/seasoning/plugins}"
SEAS_CACHE="${SEASONING_CACHE:-$HOME/.cache/seasoning}"

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

# ---------- output detection ----------
which-output() {
  if [[ -n "${WAYBAR_OUTPUT_NAME-}" ]]; then printf '%s\n' "$WAYBAR_OUTPUT_NAME"; return; fi
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[]|select(.focused==true or .active==true)|.name' | head -n1 && return
  fi
  if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    swaymsg -r -t get_outputs | jq -r '.[]|select(.focused==true)|.name' | head -n1 && return
  fi
  printf '%s\n' default
}

# ---------- state helpers ----------
_state_dir(){ mkdir -p "$SEAS_CACHE/$1"; printf '%s\n' "$SEAS_CACHE/$1"; }
_state_path(){ local out="$1" key="$2"; printf '%s/%s.state\n' "$(_state_dir "$out")" "$key"; }
_read_int(){ local v; v="$(cat "$1" 2>/dev/null || echo 0)"; [[ "$v" =~ ^[0-9]+$ ]] || v=0; printf '%s\n' "$v"; }
_write_int(){ local f="$1" v="$2" t; t="$(mktemp)"; printf '%s' "$v" >"$t"; mv -f "$t" "$f"; }
_cycle_idx(){ # cur n dir -> nxt
  local cur="$1" n="$2" dir="${3:-cycle}"; (( n<=0 )) && { echo 0; return; }
  case "$dir" in prev) echo $(( (cur-1+n)%n ));; *) echo $(( (cur+1)%n ));; esac
}
send_signal(){ local n="${1:-6}"; pkill -x -RTMIN+"$n" waybar 2>/dev/null || true; }
list_outputs(){ shopt -s nullglob; for d in "$SEAS_CACHE"/*; do [[ -d "$d" ]] && printf '%s\n' "${d##*/}"; done; shopt -u nullglob; }

# ---------- discovery ----------
_list_mid(){
  shopt -s nullglob
  local a=() f
  for f in "$SEAS_PLUGINS"/0??-*; do [[ -f "$f" && -x "$f" ]] && a+=("$f"); done
  shopt -u nullglob
  printf '%s\n' "${a[@]}" | sort -V
}
_pair_prefix_of(){ # /path/110-descriptive-left -> 110-descriptive
  local b="${1##*/}"; echo "${b%-left}"; echo "${b%-right}" >/dev/null
}
_list_pair_prefixes(){
  shopt -s nullglob
  local L R pre a=()
  for L in "$SEAS_PLUGINS"/*-left; do
    [[ -f "$L" && -x "$L" ]] || continue
    pre="${L##*/}"; pre="${pre%-left}"
    R="$SEAS_PLUGINS/$pre-right"
    [[ -f "$R" && -x "$R" ]] && a+=("$pre")
  done
  shopt -u nullglob
  printf '%s\n' "${a[@]}" | sort -V
}

# ---------- runners ----------
run_mid(){
  local out; out="$(which-output)"
  mapfile -t arr < <(_list_mid)
  if (( ${#arr[@]} == 0 )); then echo '{"text":"[seasoning:mid:no-plugins]"}'; return 0; fi
  local f idx p ret
  f="$(_state_path "$out" mid)"; idx="$(_read_int "$f")"
  (( idx = idx % ${#arr[@]} ))
  p="${arr[$idx]}"
  ret="$("$p" 2>/dev/null || true)"
  [[ -n "$ret" ]] || ret='{"text":"[?]"}'
  printf '%s\n' "$ret"
}

run_side(){
  local side="${1:-left}"; [[ "$side" =~ ^(left|right)$ ]] || side="left"
  local out; out="$(which-output)"
  mapfile -t pre < <(_list_pair_prefixes)
  if (( ${#pre[@]} == 0 )); then echo "[seasoning:side:no-pairs]"; return 0; fi
  local f idx key plug
  f="$(_state_path "$out" pairs)"; idx="$(_read_int "$f")"
  (( idx = idx % ${#pre[@]} ))
  key="${pre[$idx]}"
  plug="$SEAS_PLUGINS/$key-$side"
  if [[ -x "$plug" ]]; then "$plug"; else echo "[?]"; fi
}

# ---------- control ----------
ctl_mid(){
  local action="${1:-cycle}"; shift || true
  local out=""; while [[ $# -gt 0 ]]; do case "$1" in --output) out="$2"; shift 2;; *) break;; esac; done
  [[ -n "$out" ]] || out="$(which-output)"
  mapfile -t arr < <(_list_mid); (( ${#arr[@]} )) || exit 1
  local f cur nxt
  case "$action" in
    cycle|prev)
      f="$(_state_path "$out" mid)"; cur="$(_read_int "$f")"; nxt="$(_cycle_idx "$cur" "${#arr[@]}" "$action")"
      _write_int "$f" "$nxt"; send_signal 6 ;;
    set)
      local v="${1:-0}"; f="$(_state_path "$out" mid)"; (( v = v % ${#arr[@]} )); _write_int "$f" "$v"; send_signal 6 ;;
    mode-next)
      # find active plugin basename (e.g. 010-sextants) and bump its mode file (unbounded; plugin mods internally)
      f="$(_state_path "$out" mid)"; cur="$(_read_int "$f")"; (( cur = cur % ${#arr[@]} ))
      local base="${arr[$cur]##*/}" mf; mf="$(_state_path "$out" "mode.$base")"
      _write_int "$mf" $(( $(_read_int "$mf") + 1 ))
      send_signal 6 ;;
    *) usage ;;
  esac
}

ctl_sides(){
  local action="${1:-cycle}"; shift || true
  local which="left" out=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --which) which="$2"; shift 2 ;;
      --output) out="$2"; shift 2 ;;
      *) break ;;
    esac
  done
  [[ -n "$out" ]] || out="$(which-output)"
  mapfile -t pre < <(_list_pair_prefixes); (( ${#pre[@]} )) || exit 1
  local f cur nxt
  case "$action" in
    cycle|prev)
      f="$(_state_path "$out" pairs)"; cur="$(_read_int "$f")"; nxt="$(_cycle_idx "$cur" "${#pre[@]}" "$action")"
      _write_int "$f" "$nxt"; send_signal 5 ;;
    set)
      local v="${1:-0}"; f="$(_state_path "$out" pairs)"; (( v = v % ${#pre[@]} )); _write_int "$f" "$v"; send_signal 5 ;;
    mode-next)
      f="$(_state_path "$out" pairs)"; cur="$(_read_int "$f")"; (( cur = cur % ${#pre[@]} ))
      local base="${pre[$cur]}-$which" mf; mf="$(_state_path "$out" "mode.$base")"
      _write_int "$mf" $(( $(_read_int "$mf") + 1 ))
      send_signal 5 ;;
    mode-sync)
      f="$(_state_path "$out" pairs)"; cur="$(_read_int "$f")"; (( cur = cur % ${#pre[@]} ))
      base="${pre[$cur]}-$which"
      src="$(_state_path "$out" "mode.$base")"
      val="$(_read_int "$src")"
      while IFS= read -r o; do
        _write_int "$(_state_path "$o" "mode.$base")" "$val"
      done < <(list_outputs)
      send_signal 5 ;;
    *) usage ;;
  esac
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
  which-output) which-output ;;
  *) usage ;;
esac
