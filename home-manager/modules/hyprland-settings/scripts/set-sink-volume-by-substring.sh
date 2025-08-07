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

# Acquire a short-lived lock to avoid racing default device swaps
exec 9>/tmp/set-sink-volume.lock
flock -w 2 9 || {
  echo "Could not acquire audio control lock" >&2
  exit 1
}

strip_ansi() {
  # Strip ANSI color codes from input
  sed -r 's/\x1b\[[0-9;]*m//g'
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

# Determine current default sink ID (line starting with *)
current_default_id=$(echo "${sinks_section}" | sed -nE 's/^\s*\*\s*([0-9]+)\..*/\1/p' | head -n1)

# Find first sink matching the provided substring (case-insensitive)
target_line=$(echo "${sinks_section}" | grep -i -m1 -- "$sink_substring" || true)
if [ -z "${target_line}" ]; then
  echo "No sink matching substring: ${sink_substring}" >&2
  exit 1
fi

target_id=$(echo "${target_line}" | sed -nE 's/^\s*\*?\s*([0-9]+)\..*/\1/p')
if [ -z "${target_id}" ]; then
  echo "Failed to parse sink ID for: ${sink_substring}" >&2
  exit 1
fi

# Only switch default if needed
switched_default=0
if [ -n "${current_default_id:-}" ] && [ "${current_default_id}" != "${target_id}" ]; then
  switched_default=1
  wpctl set-default "${target_id}" || true
  # small delay to allow listeners (e.g., hyprpanel) to register default change
  sleep 0.03
fi

# Perform the requested action against the default sink (now pointing to target)
case "${action}" in
  *%+|*%-)
    # raise/lower volume; apply limit when raising
    if [[ "${action}" == *%+* ]]; then
      wpctl set-volume -l "${VOLUME_LIMIT}" @DEFAULT_AUDIO_SINK@ "${action}"
    else
      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${action}"
    fi
    ;;
  toggle-mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
  mute-on)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
    ;;
  mute-off)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    ;;
  *)
    echo "Unknown action: ${action}" >&2
    exit 1
    ;;
esac

# Play a short feedback sound (like GNOME/KDE) if available
if command -v canberra-gtk-play >/dev/null 2>&1; then
  # -V volume [0.0..1.5] (best-effort, harmless if unsupported)
  canberra-gtk-play -i audio-volume-change -V 1.0 >/dev/null 2>&1 || true
fi

# Restore previous default if we switched it
if [ "${switched_default}" -eq 1 ] && [ -n "${current_default_id:-}" ]; then
  # brief pause to ensure volume-change/OSD registered first
  sleep 0.05
  wpctl set-default "${current_default_id}" || true
fi

exit 0 