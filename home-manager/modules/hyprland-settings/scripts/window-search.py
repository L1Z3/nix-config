#!/usr/bin/env python3

import os
import json
import re
import sys
import subprocess

def map_window_to_rofi_entry(w):
    """
    Formats window data for rofi.
    The format is "DISPLAY_TEXT\0icon\x1fICON_NAME".
    - DISPLAY_TEXT includes the title, address, and workspace ID.
    - ICON_NAME is the window's class, which rofi uses to find the icon.
    """
    title = w["title"]
    address = w["address"]
    workspace_id = w["workspace"]["id"]
    icon_name = w["class"]
    
    display_text = f"{title} ({address}_{workspace_id})"
    
    return f"{display_text}\0icon\x1f{icon_name}"

def main():
    """
    Main function to get windows, present them in rofi, and focus the selection.
    """
    try:
        windows_json = os.popen("hyprctl -j clients").read()
        windows = json.loads(windows_json)

        filtered_windows = [w for w in windows if w["workspace"]["id"] != -1]

        rofi_entries = [map_window_to_rofi_entry(w) for w in filtered_windows]
        rofi_input = "\n".join(rofi_entries)

        rofi_process = subprocess.run(
            ["rofi", "-dmenu", "-i", "-p", "Switch Window"],
            input=rofi_input,
            capture_output=True,
            text=True
        )

        if rofi_process.returncode == 1:
            return

        if rofi_process.returncode != 0:
            sys.stderr.write(f"Rofi exited with an error:\n{rofi_process.stderr}")
            return
            
        selected_entry = rofi_process.stdout.strip()

        if selected_entry:
            match = re.search(r"\(([^()]+)\)$", selected_entry)
            
            if match:
                addr_and_workspace = match.group(1)
                addr = addr_and_workspace.split("_")[0]
                os.system(f"hyprctl dispatch focuswindow address:{addr}")
            else:
                sys.stderr.write(f"Error: Could not parse address from selection: '{selected_entry}'\n")

    except json.JSONDecodeError:
        sys.stderr.write("Error: Could not parse JSON from hyprctl. Is Hyprland running?\n")
    except Exception as e:
        sys.stderr.write(f"An unexpected error occurred: {e}\n")

if __name__ == "__main__":
    main()