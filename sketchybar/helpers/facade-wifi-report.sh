#!/bin/bash
set -euo pipefail

app="$HOME/.local/share/sketchybar/Facade Wi-Fi.app"
result=$(mktemp "${TMPDIR:-/tmp}/facade-wifi.XXXXXX")
trap '/bin/rm -f "$result"' EXIT
if [ "${1:-}" = request ]; then
  /usr/bin/open -n -W -a "$app" --args "$result" request
else
  /usr/bin/open -g -n -W -a "$app" --args "$result"
fi
/bin/cat "$result"
