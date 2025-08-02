#!/usr/bin/env python3

import os
import json
import re
import sys
import subprocess
import html

# --- CONFIGURATION ---
# adjust this value to fit the width of the rofi window
MAX_WIDTH = 62
ELLIPSIS = "..."

def create_display_text(title, suffix):
    """
    Truncates the title to ensure the entire string
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
    Formats window data for Rofi, hiding the address/other metadata with Pango markup
    """
    # capture the name from my special workspace naming scheme
    if re.search(r"special\:scratch[0-9|A-z]", w["workspace"]["name"]):
        effective_workspace = "s" + w["workspace"]["name"][-1]
    elif re.search(r"special\:.*", w["workspace"]["name"]):
        effective_workspace = "s_" + w["workspace"]["name"].split(":")[1]
    else:
        effective_workspace = w["workspace"]["id"]
    visible_suffix = f" ({effective_workspace})"
    display_text = create_display_text(w['title'], visible_suffix)

    sanitized_title = re.sub(r'[^a-zA-Z0-9\s]', '', w['title'])

    # append class and full title to invisible part so that we can search by them
    invisible_part = f"<span fgalpha='1'>{w['address']}_{w['class']}_{sanitized_title}</span>"
    
    full_text = display_text + invisible_part
    
    icon_name = w["class"]
    return f"{full_text}\0icon\x1f{icon_name}"

def main():
    try:
        windows_json = os.popen("hyprctl -j clients").read()
        windows = json.loads(windows_json)

        filtered_windows = [w for w in windows if w["class"] != "xwaylandvideobridge"]

        # sorted_windows = sorted(filtered_windows, key=lambda w: w['focusHistoryID'])
        
        rofi_entries = [map_window_to_rofi_entry(w) for w in filtered_windows]
        rofi_input = "\n".join(rofi_entries)

        rofi_process = subprocess.run(
            ["rofi", "-dmenu", "-i", "-p", "Switch Window:", "-markup-rows"],
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
            match = re.search(r"<span.*?>([^_]+)_", selected_entry)
            if match:
                addr = match.group(1)
                os.system(f"hyprctl dispatch focuswindow address:{addr}")
            else:
                sys.stderr.write(f"Error: Could not parse address from Pango markup in selection: '{selected_entry}'\n")

    except Exception as e:
        sys.stderr.write(f"An unexpected error occurred: {e}\n")

if __name__ == "__main__":
    main()