#!/usr/bin/env bash
# seasoning-ticker — smart timing service for Waybar modules
# Reads plugin configs and sends appropriate signals based on update rates
set -euo pipefail

# Waybar signals (fixed)
SIGNAL_LEFT=5
SIGNAL_MID=6
SIGNAL_RIGHT=7

# Internal time boundary tracking (not sent to waybar directly)
BOUNDARY_SECOND=1
BOUNDARY_MINUTE=2
BOUNDARY_HOUR=4
BOUNDARY_DAY=8

SEAS_PLUGINS="${SEAS_PLUGINS:-/usr/share/seasoning/plugins}"
SEAS_CACHE="${SEASONING_CACHE:-$HOME/.cache/seasoning}"

# Config file lookup: user config takes precedence over system default
if [[ -f "$HOME/.config/seasoning/settings.json" ]]; then
  CONFIG_FILE="$HOME/.config/seasoning/settings.json"
elif [[ -f "/usr/share/seasoning/settings.json" ]]; then
  CONFIG_FILE="/usr/share/seasoning/settings.json"
else
  CONFIG_FILE=""  # No config, use defaults
fi

LOG_FILE="${HOME}/.cache/seasoning/ticker.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

send_signal() {
  local sig="$1"
  pkill -x -RTMIN+"$sig" waybar 2>/dev/null || true
}

# Time boundary detection
check_boundaries() {
  local S M H
  read -r H M S < <(date '+%H %M %S')
  local boundaries=$BOUNDARY_SECOND
  
  if [[ "$S" == "00" ]]; then
    boundaries=$((boundaries | BOUNDARY_MINUTE))
  fi
  if [[ "$M" == "00" && "$S" == "00" ]]; then
    boundaries=$((boundaries | BOUNDARY_HOUR))
  fi
  if [[ "$H" == "00" && "$M" == "00" && "$S" == "00" ]]; then
    boundaries=$((boundaries | BOUNDARY_DAY))
  fi
  
  echo "$boundaries"
}

# Convert update rate string to boundary flag
rate_to_boundary() {
  case "${1:-second}" in
    second) echo $BOUNDARY_SECOND ;;
    minute) echo $BOUNDARY_MINUTE ;;
    hour)   echo $BOUNDARY_HOUR ;;
    day)    echo $BOUNDARY_DAY ;;
    *)      echo $BOUNDARY_SECOND ;;
  esac
}

# Read update rate from config for a plugin
get_update_rate() {
  local section="$1"  # "mid" or "sides"
  local plugin="$2"   # plugin name
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "second"
    return
  fi
  
  # Try to extract from config.json using grep/sed (no jq dependency)
  # Format: "plugin-name": "rate"
  local rate
  rate=$(grep -A 20 "\"$section\"" "$CONFIG_FILE" | \
         grep -A 10 '"update_rates"' | \
         grep "\"$plugin\"" | \
         sed -n 's/.*"\([^"]*\)"[[:space:]]*$/\1/p' | \
         head -1)
  
  echo "${rate:-second}"
}

# Get active plugin for a position on a monitor
get_active_plugin() {
  local output="$1"
  local position="$2"  # "mid" or "pairs"
  
  local state_file="$SEAS_CACHE/$output/$position.state"
  if [[ ! -f "$state_file" ]]; then
    echo ""
    return
  fi
  
  local idx
  idx=$(cat "$state_file" 2>/dev/null || echo 0)
  
  # List available plugins/pairs
  case "$position" in
    mid)
      mapfile -t arr < <(find "$SEAS_PLUGINS" -name '0??-*' -type f -executable | sort -V)
      if (( ${#arr[@]} > 0 && idx < ${#arr[@]} )); then
        basename "${arr[$idx]}"
      fi
      ;;
    pairs)
      mapfile -t arr < <(find "$SEAS_PLUGINS" -name '*-left' -type f -executable | \
                         sed 's/-left$//' | sort -V | xargs -I{} basename {})
      if (( ${#arr[@]} > 0 && idx < ${#arr[@]} )); then
        echo "${arr[$idx]}"
      fi
      ;;
  esac
}

# List all monitors
list_outputs() {
  find "$SEAS_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
    xargs -I{} basename {} || echo "default"
}

# Check if a module needs updating based on boundary
should_update() {
  local rate="$1"
  local boundaries="$2"
  local required
  required=$(rate_to_boundary "$rate")
  
  (( (boundaries & required) != 0 ))
}

# Load config at startup
log "Seasoning ticker started (smart mode)"
log "Config: $CONFIG_FILE"
log "Plugins: $SEAS_PLUGINS"
log "Cache: $SEAS_CACHE"

# Main loop
while true; do
  # Sleep until next second boundary
  nanos=$(date +%N)
  nanos=${nanos#"${nanos%%[!0]*}"}
  [[ -z "$nanos" ]] && nanos=0
  
  sleep_nanos=$((1000000000 - nanos))
  sleep_seconds=$(awk "BEGIN {printf \"%.6f\", $sleep_nanos / 1000000000}")
  sleep "$sleep_seconds"
  
  # Check what boundaries we're at
  boundaries=$(check_boundaries)
  
  # For each monitor, check what needs updating
  while IFS= read -r output; do
    [[ -z "$output" ]] && continue
    
    # Check mid module
    mid_plugin=$(get_active_plugin "$output" "mid")
    if [[ -n "$mid_plugin" ]]; then
      mid_rate=$(get_update_rate "mid" "$mid_plugin")
      if should_update "$mid_rate" "$boundaries"; then
        send_signal $SIGNAL_MID
      fi
    fi
    
    # Check side modules (left and right use same pair)
    pair_prefix=$(get_active_plugin "$output" "pairs")
    if [[ -n "$pair_prefix" ]]; then
      # Check left
      left_plugin="${pair_prefix}-left"
      left_rate=$(get_update_rate "sides" "$left_plugin")
      
      # Check right
      right_plugin="${pair_prefix}-right"
      right_rate=$(get_update_rate "sides" "$right_plugin")
      
      # Send signals if needed (they might have different rates!)
      if should_update "$left_rate" "$boundaries"; then
        send_signal $SIGNAL_LEFT
      fi
      if should_update "$right_rate" "$boundaries"; then
        send_signal $SIGNAL_RIGHT
      fi
    fi
  done < <(list_outputs)
done