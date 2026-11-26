#!/bin/bash
# Check capsule spacing and alignment on each connected display.
set -euo pipefail

exec /opt/homebrew/bin/python3 - <<'PY'
import json
import subprocess

def query(name):
    return json.loads(subprocess.check_output(["/opt/homebrew/bin/sketchybar", "--query", name]))

def check(actual, expected, detail):
    if abs(actual - expected) > 1:
        raise ValueError(f"{detail}: {actual:g} pt, expected {expected:g} pt")

def check_group(items, names, gap=7):
    for left, right in zip(names, names[1:]):
        check(items[right][0] - items[left][1], gap, f"{left} → {right}")

for display in query("displays"):
    display_id = display["arrangement-id"]
    items = {}
    positions = {}
    for name in ("desktop", "clock", "wifi", "audio", "battery"):
        item = query(f"facade.{name}.{display_id}")
        positions[name] = item["geometry"]["position"]
        rect = item["bounding_rects"][f"display-{display_id}"]
        x = rect["origin"][0]
        items[name] = (x, x + rect["size"][0])
        check(item["geometry"]["background"]["height"], 28, f"{name} height")
        check(item["geometry"]["y_offset"], -5, f"{name} vertical offset")
    frame = display["frame"]
    center = frame["x"] + frame["w"] / 2
    if positions["desktop"] == "q":
        check_group(items, ("desktop", "audio", "wifi"))
        check_group(items, ("clock", "battery"))
        check(items["wifi"][1], center - 105, "left notch edge")
        check(items["clock"][0], center + 105, "right notch edge")
    else:
        check_group(items, ("desktop", "audio"))
        check_group(items, ("wifi", "battery"))
        check(items["desktop"][0] - frame["x"], 14, "left margin")
        check(frame["x"] + frame["w"] - items["battery"][1], 14, "right margin")
        check(sum(items["clock"]) / 2, center, "clock centre")
    print(f"Display {display_id}: capsule spacing and alignment OK")
PY
