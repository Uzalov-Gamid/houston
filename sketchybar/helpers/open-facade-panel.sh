#!/bin/bash
set -euo pipefail
display="${1:-}"
[[ "$display" =~ ^[0-9]+$ ]] || exit 1
bar=/opt/homebrew/bin/sketchybar
jq=/opt/homebrew/bin/jq
screen=$("$bar" --query displays | "$jq" -er --argjson display "$display" '.[] | select(."arrangement-id"==$display).DirectDisplayID')
center=$("$bar" --query "facade.clock.$display" | "$jq" -er --arg key "display-$display" '.bounding_rects[$key] | .origin[0]+.size[0]/2')
app="$HOME/.local/share/sketchybar/Facade Panel.app"
if /usr/bin/pgrep -u "$(/usr/bin/id -u)" -x FacadePanel >/dev/null; then
  /usr/bin/open -g -a "$app"
else
  snapshot=$(mktemp "${TMPDIR:-/tmp}/facade-panel-notices.XXXXXX")
  /opt/homebrew/bin/python3 "$HOME/.config/sketchybar/helpers/facade-notifications.py" > "$snapshot"
  if ! /usr/bin/open -g -a "$app" --args "$screen" "$center" "$snapshot"; then
    /bin/rm -f "$snapshot"
    exit 1
  fi
fi
