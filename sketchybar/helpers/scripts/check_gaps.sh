#!/bin/bash
# Measures every visible capsule on the bar and checks that the space
# between neighbours is the same everywhere (and not under the notch).
# Run after changing widgets:  ~/.config/sketchybar/helpers/scripts/check_gaps.sh
#
# The left group and the right group are checked separately: the space between
# them (the notch, or free space on a monitor without one) can be any size.
#
# A "capsule" is any visible item or bracket that draws a background,
# except items that sit inside a bracket (the bracket is the capsule) and
# items inside popups.
#
# Widgets on the plate are checked too: the step between their slots has to be
# the same. A slot can be wider than its glyph, so this doesn't see the ink.
# The battery glyph and the digits have empty space of their own (4pt and 1pt),
# compensated in battery.lua and calendar.lua.

GAP=7         # settings.paddings.container_paddings
STEP=15       # capsule.step, between widgets on the plate
EDGE_LEFT=9   # settings.paddings.edge_padding: the square piece before the left plate
EDGE_RIGHT=0  # the right plate runs up to the screen edge
# Notch of the main display, in points, read from macOS (-1 if there is none,
# e.g. on an external monitor), plus the screen width.
read -r NOTCH_L NOTCH_R SCREEN_W < <(swift -e '
import AppKit
let s = NSScreen.main!
let l = s.auxiliaryTopLeftArea?.width ?? 0, r = s.auxiliaryTopRightArea?.width ?? 0, w = s.frame.width
if l > 0 && r > 0 { print(Int(l), Int(w - r), Int(w)) } else { print(-1, -1, Int(w)) }
' 2>/dev/null || echo "-1 -1 1470")

items=$(sketchybar --query bar | jq -r '.items[]')

# members of brackets are drawn as part of the bracket
members=$(for i in $items; do
  sketchybar --query "$i" | jq -r 'select(.type == "bracket") | .bracket[]?'
done)

rects=$(for i in $items; do
  echo "$members" | grep -qx "$i" && continue
  sketchybar --query "$i" | jq -r --arg i "$i" '
    select(.geometry.drawing == "on")
    | select(.geometry.position | startswith("popup") | not)
    | select(.type == "bracket" or .geometry.background.drawing == "on")
    | .bounding_rects["display-1"] // empty
    | select(.origin[0] >= 0)  # hidden brackets are parked at -9999
    | "\(.origin[0]) \(.size[0]) \($i)"'
done | grep -v another_edge_padding | sort -n)

screen_w=$SCREEN_W

# widgets.battery.value is an overlay
sketchybar --query widgets.plate | jq -r '.bracket[]' | while read -r i; do
  sketchybar --query "$i" | jq -r --arg i "$i" '.bounding_rects["display-1"] // empty | "\(.origin[0]) \(.size[0]) \($i)"'
done | grep -vE 'widgets.battery.value|widgets.plate.tail' | sort -n | awk -v step=$STEP '
  NR > 1 && $1 - prev_end != step - ($3 == "widgets.battery" ? 4 : $3 == "widgets.calendar" ? 1 : 0) {
    printf "✗ %-28s → %-28s step %.0f (want %d)\n", prev, $3, $1 - prev_end, step; bad = 1
  }
  { prev = $3; prev_end = $1 + $2 }
  END { if (!bad) printf "✓ all steps on the plate %d pt\n", step; exit bad }' || exit 1

echo "$rects" | awk -v gap=$GAP -v eleft=$EDGE_LEFT -v eright=$EDGE_RIGHT -v nl=$NOTCH_L -v nr=$NOTCH_R -v w="$screen_w" '
  { x = $1; end = $1 + $2; name = $3 }
  NR == 1 { if (x != eleft) { printf "✗ left edge %.0f (want %d)\n", x, eleft; bad = 1 } }
  NR > 1 {
    g = x - prev_end
    # the gap between the left and the right group (notch or just free space) is not checked
    across_notch = (prev_end <= nl && x >= nr) || (prev_end <= w / 2 && x >= w / 2)
    if (!across_notch && g != gap) { printf "✗ %-28s → %-28s gap %.0f (want %d)\n", prev, name, g, gap; bad = 1 }
  }
  { if (x < nr && end > nl) { printf "✗ %s overlaps the notch (%.0f–%.0f)\n", name, x, end; bad = 1 }
    prev = name; prev_end = end }
  END {
    if (w - prev_end != eright) { printf "✗ right edge %.0f (want %d)\n", w - prev_end, eright; bad = 1 }
    if (!bad) printf "✓ all gaps %d pt, edges %d/%d pt, nothing under the notch (%d capsules)\n", gap, eleft, eright, NR
    exit bad
  }'
