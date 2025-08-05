#!/usr/bin/env python3

import os
import json
import re
import sys
import subprocess
import html

# --- CONFIGURATION ---
# Adjust this value to fit the width of your Rofi window.
# It's the total maximum number of characters for the entire line.
MAX_WIDTH = 50
ELLIPSIS = "..."

def create_display_text(title, suffix):
    """
    Intelligently truncates the title to ensure the entire string
    with its suffix fits within MAX_WIDTH.
    """
    safe_title = html.escape(title)
    
    if len(safe_title) + len(suffix) <= MAX_WIDTH:
        return safe_title + suffix

    available_space = MAX_WIDTH - len(suffix) - len(ELLIPSIS)

    if available_space < 0:
        return suffix[:MAX_WIDTH]

    return safe_title[:available_space] + ELLIPSIS + suffix

def map_window_to_rofi_entry(w):
    """
    Formats window data for Rofi, including manual truncation of the title.
    """
    suffix = f" ({w['address']}_{w['workspace']['id']})"
    
    display_text = create_display_text(w["title"], suffix)
    
    icon_name = w["class"]
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

    except Exception as e:
        sys.stderr.write(f"An unexpected error occurred: {e}\n")

if __name__ == "__main__":
    main()