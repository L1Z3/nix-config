#!/usr/bin/env bash
set -euo pipefail

# Usage: set-sink-volume-by-substring.sh <sink_substring> <volume_change>
# Examples:
#   set-sink-volume-by-substring.sh "Speaker" 5%+
#   set-sink-volume-by-substring.sh "WF-1000XM5" 5%-

if [ $# -lt 2 ]; then
  echo "Usage: $0 <sink_substring> <volume_change>" >&2
  exit 1
fi

sink_substring="$1"
action="$2"

VOLUME_LIMIT="1.5"

strip_ansi() {
  sed -r 's/\x1b\[[0-9;]*m//g'
}

# parse wpctl status and find target sink ID by substring
status_raw=$(wpctl status 2>/dev/null | strip_ansi || true)
if [ -z "${status_raw}" ]; then
  echo "wpctl status returned no output" >&2
  exit 1
fi

sinks_section=$(echo "${status_raw}" | awk '/Sinks:/{flag=1;next} /Sources:/{flag=0} flag')
if [ -z "${sinks_section}" ]; then
  echo "No sinks found in wpctl status output" >&2
  exit 1
fi

processed_sinks=$(echo "${sinks_section}" | sed 's/^[^0-9*]*//')

target_line=$(echo "${processed_sinks}" | grep -i -m1 -- "$sink_substring" || true)
if [ -z "${target_line}" ]; then
  echo "No sink matching substring: ${sink_substring}" >&2
  exit 1
fi

target_id=$(echo "${target_line}" | sed -nE 's/^\*?\s*([0-9]+)\..*/\1/p')
if [ -z "${target_id}" ]; then
  echo "Failed to parse sink ID for: ${sink_substring}" >&2
  echo "Line: ${target_line}" >&2
  exit 1
fi

# increase/decrease the volume on the target sink ID
case "${action}" in
  *%+)
    wpctl set-volume -l "${VOLUME_LIMIT}" "${target_id}" "${action}"
    ;;
  *%-)
    wpctl set-volume "${target_id}" "${action}"
    ;;
  *)
    echo "Unsupported action. Use formats like 5%+ or 5%-" >&2
    exit 1
    ;;
esac

# read current volume/mute of target sink after adjustment
vol_line=$(wpctl get-volume "${target_id}" 2>/dev/null || true)
vol_num=$(echo "$vol_line" | awk '{print $2}')
muted_flag=$(echo "$vol_line" | grep -qi 'MUTED' && echo true || echo false)
vol_pct=$(awk -v v="$vol_num" 'BEGIN{printf "%d", v*100}')

# play indicator sound on the proper device
node_name=$(pw-cli info "${target_id}" 2>/dev/null | sed -nE 's/^[[:space:]]*\*?[[:space:]]*node\.name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' | head -n1)
if command -v canberra-gtk-play >/dev/null 2>&1; then
  if [ -n "${node_name}" ]; then
    PULSE_SINK="${node_name}" canberra-gtk-play -i audio-volume-change -V 1.0 >/dev/null 2>&1 || true
  else
    canberra-gtk-play -i audio-volume-change -V 1.0 >/dev/null 2>&1 || true
  fi
fi

# show HyprPanel OSD for this change (possible because of hyprpanel patch)
if command -v hyprpanel >/dev/null 2>&1; then
  hyprpanel osdv "${vol_pct}" "${muted_flag}" >/dev/null 2>&1 || true
fi

exit 0 