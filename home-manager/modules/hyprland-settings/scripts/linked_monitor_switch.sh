#!/usr/bin/env bash

set -e

if ! command -v hyprctl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: This script requires 'hyprctl' and 'jq'. Please install them." >&2
    exit 1
fi

if [ "$#" -ne 1 ];
then
    echo "Usage: $0 <workspace>"
    echo "  <workspace>: Can be an absolute number (e.g., 1-10) or relative (+N or -N)."
    echo "Example: $0 3   (go to workspace 3 on all monitors)"
    echo "Example: $0 +1  (go to the next workspace on all monitors, wraps around)"
    exit 1
fi

INPUT="$1"

# determine current state
ACTIVE_WORKSPACE_DATA=$(hyprctl activeworkspace -j)
if [ -z "$ACTIVE_WORKSPACE_DATA" ]; then
    echo "Error: Could not determine active workspace." >&2
    exit 1
fi

ACTIVE_WORKSPACE_NAME=$(echo "$ACTIVE_WORKSPACE_DATA" | jq -r '.name')
ACTIVE_MONITOR_ID=$(echo "$ACTIVE_WORKSPACE_DATA" | jq '.monitorID')

# determine the target local workspace number/name
TARGET_LOCAL_WORKSPACE=""

# handle relative vs absolute input
case "$INPUT" in
    +*|-*)
        # --- RELATIVE MODE (+N or -N) ---
        OFFSET=$(echo "$INPUT" | sed 's/+//')

        mapfile -t CURRENT_MONITOR_WORKSPACES < <(hyprctl workspaces -j | jq --argjson mon_id "$ACTIVE_MONITOR_ID" -r '[.[] | select(.monitorID == $mon_id) | .name] | .[]' | sort -n)

        NUM_WORKSPACES=${#CURRENT_MONITOR_WORKSPACES[@]}
        if [ "$NUM_WORKSPACES" -eq 0 ]; then
            echo "Error: No workspaces found on the active monitor." >&2
            exit 1
        fi

        CURRENT_INDEX=-1
        for i in "${!CURRENT_MONITOR_WORKSPACES[@]}"; do
           if [[ "${CURRENT_MONITOR_WORKSPACES[$i]}" == "$ACTIVE_WORKSPACE_NAME" ]]; then
               CURRENT_INDEX=$i
               break
           fi
        done

        if [ "$CURRENT_INDEX" -eq -1 ]; then
             echo "Error: Could not find active workspace '$ACTIVE_WORKSPACE_NAME' in the list." >&2
             exit 1
        fi

        NEW_INDEX=$(( (CURRENT_INDEX + OFFSET % NUM_WORKSPACES + NUM_WORKSPACES) % NUM_WORKSPACES ))

        TARGET_LOCAL_WORKSPACE=${CURRENT_MONITOR_WORKSPACES[$NEW_INDEX]}
        ;;
    *)
        # --- ABSOLUTE MODE (e.g., 3) ---
        if ! [[ "$INPUT" =~ ^[1-9]$|^10$ ]]; then
            echo "Error: Absolute workspace must be a number between 1 and 10." >&2
            exit 1
        fi
        TARGET_LOCAL_WORKSPACE=$INPUT
        ;;
esac

echo "Target local workspace: $TARGET_LOCAL_WORKSPACE"

# 3. Build and dispatch commands
mapfile -t ALL_MONITOR_IDS < <(hyprctl monitors -j | jq -r '.[].id')

OTHER_MONITOR_CMDS=()
ACTIVE_MONITOR_CMD=""

WORKSPACE_DISPATCH_CMD="split:workspace $TARGET_LOCAL_WORKSPACE"

for MONITOR_ID in "${ALL_MONITOR_IDS[@]}"; do
    if [ "$MONITOR_ID" -eq "$ACTIVE_MONITOR_ID" ]; then
        ACTIVE_MONITOR_CMD=$WORKSPACE_DISPATCH_CMD
    else
        OTHER_MONITOR_CMDS+=("dispatch focusmonitor $MONITOR_ID" "dispatch $WORKSPACE_DISPATCH_CMD")
    fi
done

if [ ${#OTHER_MONITOR_CMDS[@]} -gt 0 ]; then
    BATCH_CMDS=$(IFS=';'; echo "${OTHER_MONITOR_CMDS[*]}")
    echo "Switching other monitors with: $BATCH_CMDS"
    hyprctl --batch "$BATCH_CMDS"
fi

if [ -n "$ACTIVE_MONITOR_CMD" ]; then
    echo "Returning focus and switching active monitor with: $ACTIVE_MONITOR_CMD"
    hyprctl dispatch focusmonitor "$ACTIVE_MONITOR_ID"
    hyprctl dispatch "$ACTIVE_MONITOR_CMD"
fi
