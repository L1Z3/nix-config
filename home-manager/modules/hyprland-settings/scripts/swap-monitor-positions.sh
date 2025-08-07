#!/usr/bin/env bash

set -euo pipefail

if ! command -v hyprctl &> /dev/null || ! command -v jq &> /dev/null; then
  echo "Error: This script requires 'hyprctl' and 'jq'." >&2
  exit 1
fi

MON_JSON=$(hyprctl monitors -j)

MAP=$(echo "$MON_JSON" | jq '[.[] | select(has("name") and has("x") and has("y") and has("width") and has("height") and has("scale"))]')
COUNT=$(echo "$MAP" | jq 'length')

if [ "$COUNT" -ne 2 ]; then
  echo "Error: Expected exactly 2 active monitors, found $COUNT." >&2
  exit 1
fi

LEFT=$(echo "$MAP" | jq 'sort_by(.x) | .[0]')
RIGHT=$(echo "$MAP" | jq 'sort_by(.x) | .[1]')

L_NAME=$(echo "$LEFT" | jq -r '.name')
L_W=$(echo "$LEFT" | jq -r '.width')
L_H=$(echo "$LEFT" | jq -r '.height')
L_HZ=$(echo "$LEFT" | jq -r '.refreshRate // .refresh // 60')
L_SCALE=$(echo "$LEFT" | jq -r '.scale')
L_X=$(echo "$LEFT" | jq -r '.x')
L_Y=$(echo "$LEFT" | jq -r '.y')
L_TRANSFORM=$(echo "$LEFT" | jq -r '.transform // 0')

R_NAME=$(echo "$RIGHT" | jq -r '.name')
R_W=$(echo "$RIGHT" | jq -r '.width')
R_H=$(echo "$RIGHT" | jq -r '.height')
R_HZ=$(echo "$RIGHT" | jq -r '.refreshRate // .refresh // 60')
R_SCALE=$(echo "$RIGHT" | jq -r '.scale')
R_X=$(echo "$RIGHT" | jq -r '.x')
R_Y=$(echo "$RIGHT" | jq -r '.y')
R_TRANSFORM=$(echo "$RIGHT" | jq -r '.transform // 0')

NEW_L_POS_X=$R_X
NEW_L_POS_Y=$R_Y
NEW_R_POS_X=$L_X
NEW_R_POS_Y=$L_Y

L_TRANS_SEG=""
if [ "$L_TRANSFORM" != "0" ]; then
  L_TRANS_SEG=",transform,$L_TRANSFORM"
fi
R_TRANS_SEG=""
if [ "$R_TRANSFORM" != "0" ]; then
  R_TRANS_SEG=",transform,$R_TRANSFORM"
fi

CMD1="keyword monitor $L_NAME,${L_W}x${L_H}@${L_HZ},${NEW_L_POS_X}x${NEW_L_POS_Y},${L_SCALE}${L_TRANS_SEG}"
CMD2="keyword monitor $R_NAME,${R_W}x${R_H}@${R_HZ},${NEW_R_POS_X}x${NEW_R_POS_Y},${R_SCALE}${R_TRANS_SEG}"

hyprctl --batch "$CMD1; $CMD2"

echo "Swapped monitor positions: $L_NAME <-> $R_NAME" 