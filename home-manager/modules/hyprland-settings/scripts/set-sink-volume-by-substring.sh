#!/usr/bin/env bash
set -euo pipefail

# Usage: set-sink-volume-by-substring.sh <sink_substring> <volume_change>
# Examples:
#   set-sink-volume-by-substring.sh "Speaker" 5%+
#   set-sink-volume-by-substring.sh "WF-1000XM5" 5%-
#   set-sink-volume-by-substring.sh "Earbuds" toggle-mute

if [ $# -lt 2 ]; then
  echo "Usage: $0 <sink_substring> <volume_change|toggle-mute|mute-on|mute-off>" >&2
  exit 1
fi

sink_substring="$1"
action="$2"

# Optional: max volume limit when raising (matches your existing binds)
VOLUME_LIMIT="1.5"
# Burst idle window in seconds; if no keypress within this window, restore original default
BURST_IDLE_WINDOW_S=0.6
# Polling interval for background restorer
RESTORE_POLL_S=0.2

# Resolve runtime dir for per-user state
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="${RUNTIME_DIR}/hypr-sink-burst"
mkdir -p "${STATE_DIR}"
# use a sanitized key based on substring
SUBKEY=$(echo -n "${sink_substring}" | tr -c 'A-Za-z0-9._-' '_' )
STATE_FILE="${STATE_DIR}/${SUBKEY}.state"
LOCK_FILE="${STATE_DIR}/${SUBKEY}.lock"

strip_ansi() {
  sed -r 's/\x1b\[[0-9;]*m//g'
}

now_s() { date +%s; }

read_kv() {
  # usage: read_kv KEY <file>
  local key="$1"; local file="$2"
  grep -E "^${key}=" -m1 "$file" 2>/dev/null | sed -nE "s/^${key}=(.*)$/\1/p" || true
}

write_state() {
  # ORIGINAL_ID, TARGET_ID, EXPIRY_S, ACTIVE
  {
    echo "ORIGINAL_ID=${1}"
    echo "TARGET_ID=${2}"
    echo "EXPIRY_S=${3}"
    echo "ACTIVE=${4}"
  } >"${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "${STATE_FILE}"
}

update_expiry() {
  local expiry="$1"
  [ -f "${STATE_FILE}" ] || return 0
  # rewrite only EXPIRY_S
  awk -v newexp="$expiry" 'BEGIN{FS=OFS="="} { if($1=="EXPIRY_S"){ $2=newexp } print }' "${STATE_FILE}" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "${STATE_FILE}"
}

# Capture current PipeWire sinks from wpctl status, stripping color codes
status_raw=$(wpctl status 2>/dev/null | strip_ansi || true)
if [ -z "${status_raw}" ]; then
  echo "wpctl status returned no output" >&2
  exit 1
fi

# Extract the Sinks section
sinks_section=$(echo "${status_raw}" | awk '/Sinks:/{flag=1;next} /Sources:/{flag=0} flag')
if [ -z "${sinks_section}" ]; then
  echo "No sinks found in wpctl status output" >&2
  exit 1
fi

# Normalize lines by stripping any non-digit/non-asterisk prefix (handles leading box-drawing chars)
processed_sinks=$(echo "${sinks_section}" | sed 's/^[^0-9*]*//')

# Determine current default sink ID (line containing a '*')
current_default_id=$(echo "${processed_sinks}" | sed -nE 's/.*\*[^0-9]*([0-9]+)\..*/\1/p' | head -n1)

# Find first sink matching the provided substring (case-insensitive)
target_line=$(echo "${processed_sinks}" | grep -i -m1 -- "$sink_substring" || true)
if [ -z "${target_line}" ]; then
  echo "No sink matching substring: ${sink_substring}" >&2
  exit 1
fi

# Parse the sink ID after optional '*' and spaces
target_id=$(echo "${target_line}" | sed -nE 's/^\*?\s*([0-9]+)\..*/\1/p')
if [ -z "${target_id}" ]; then
  echo "Failed to parse sink ID for: ${sink_substring}" >&2
  echo "Line: ${target_line}" >&2
  exit 1
fi

# Acquire per-substring lock to coordinate burst state and switching
exec 9>"${LOCK_FILE}"
flock -w 0.2 9 || {
  # If we cannot acquire quickly, still attempt to do the action directly on target id (fast path)
  case "${action}" in
    *%+|*%-)
      if [[ "${action}" == *%+* ]]; then
        wpctl set-volume -l "${VOLUME_LIMIT}" "${target_id}" "${action}"
      else
        wpctl set-volume "${target_id}" "${action}"
      fi
      ;;
    toggle-mute)
      wpctl set-mute "${target_id}" toggle ;;
    mute-on)
      wpctl set-mute "${target_id}" 1 ;;
    mute-off)
      wpctl set-mute "${target_id}" 0 ;;
  esac
  # best-effort sound
  if command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -i audio-volume-change -V 1.0 >/dev/null 2>&1 || true; fi
  exit 0
}

# Read existing state if present
ACTIVE=""
if [ -f "${STATE_FILE}" ]; then
  ACTIVE=$(read_kv ACTIVE "${STATE_FILE}")
fi

now=$(now_s)
new_expiry=$(( now + ${BURST_IDLE_WINDOW_S%.*} ))

if [ "${ACTIVE}" = "1" ]; then
  # Active burst: refresh expiry and ensure default still points to target
  prior_target=$(read_kv TARGET_ID "${STATE_FILE}")
  original_id=$(read_kv ORIGINAL_ID "${STATE_FILE}")
  update_expiry "$new_expiry"
  current_default_id_checked=$(echo "${processed_sinks}" | sed -nE 's/.*\*[^0-9]*([0-9]+)\..*/\1/p' | head -n1)
  if [ -n "$current_default_id_checked" ] && [ "$current_default_id_checked" != "$prior_target" ]; then
    wpctl set-default "$prior_target" || true
  fi
else
  # Start a new burst: save original, switch default to target, set state
  original_id="${current_default_id:-}"
  write_state "$original_id" "$target_id" "$new_expiry" 1
  wpctl set-default "${target_id}" || true
  # Spawn a background restorer
  ( 
    while true; do
      sleep "$RESTORE_POLL_S"
      # lock briefly to check state
      exec 10>"${LOCK_FILE}"; flock -w 0.1 10 || continue
      if [ ! -f "${STATE_FILE}" ]; then
        exec 10>&-; break
      fi
      ACTIVE_BG=$(read_kv ACTIVE "${STATE_FILE}")
      EXP_BG=$(read_kv EXPIRY_S "${STATE_FILE}")
      ORIG_BG=$(read_kv ORIGINAL_ID "${STATE_FILE}")
      TGT_BG=$(read_kv TARGET_ID "${STATE_FILE}")
      now_bg=$(date +%s)
      if [ "${ACTIVE_BG}" != "1" ]; then
        exec 10>&-; break
      fi
      if [ -n "${EXP_BG}" ] && [ "$now_bg" -ge "$EXP_BG" ]; then
        # time to restore
        if [ -n "${ORIG_BG}" ]; then
          # only restore if default is still pointing to target
          status_raw_bg=$(wpctl status 2>/dev/null | strip_ansi || true)
          sinks_section_bg=$(echo "${status_raw_bg}" | awk '/Sinks:/{flag=1;next} /Sources:/{flag=0} flag')
          processed_sinks_bg=$(echo "${sinks_section_bg}" | sed 's/^[^0-9*]*//')
          cur_def_bg=$(echo "${processed_sinks_bg}" | sed -nE 's/.*\*[^0-9]*([0-9]+)\..*/\1/p' | head -n1)
          if [ "$cur_def_bg" = "$TGT_BG" ]; then
            wpctl set-default "$ORIG_BG" || true
          fi
        fi
        # mark inactive and cleanup
        write_state "${ORIG_BG}" "${TGT_BG}" "$now_bg" 0
        rm -f "${STATE_FILE}"
        exec 10>&-; break
      fi
      exec 10>&-
    done
  ) >/dev/null 2>&1 & disown
fi

# Perform the requested action against the target sink ID directly (no default switch)
case "${action}" in
  *%+|*%-)
    if [[ "${action}" == *%+* ]]; then
      wpctl set-volume -l "${VOLUME_LIMIT}" "${target_id}" "${action}"
    else
      wpctl set-volume "${target_id}" "${action}"
    fi
    ;;
  toggle-mute)
    wpctl set-mute "${target_id}" toggle ;;
  mute-on)
    wpctl set-mute "${target_id}" 1 ;;
  mute-off)
    wpctl set-mute "${target_id}" 0 ;;
  *)
    echo "Unknown action: ${action}" >&2
    exit 1 ;;
esac

# Query current volume/mute of target sink to show OSD via HyprPanel CLI
vol_line=$(wpctl get-volume "${target_id}" 2>/dev/null || true)
# parse: Volume: 0.60 [MUTED]
vol_num=$(echo "$vol_line" | awk '{print $2}')
muted_flag=$(echo "$vol_line" | grep -qi 'MUTED' && echo true || echo false)

if command -v hyprpanel >/dev/null 2>&1; then
  vol_pct=$(awk -v v="$vol_num" 'BEGIN{printf "%d", v*100}')
  hyprpanel osdv "$vol_pct" "$muted_flag" >/dev/null 2>&1 || true
fi

# Play a short feedback sound (like GNOME/KDE)
if command -v canberra-gtk-play >/dev/null 2>&1; then
  canberra-gtk-play -i audio-volume-change -V 1.0 >/dev/null 2>&1 || true
fi

exit 0 