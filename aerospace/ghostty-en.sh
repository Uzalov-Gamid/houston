#!/bin/bash
# Ignore empty workspaces and resolve the focused window without querying AeroSpace.
[ -n "${AEROSPACE_WINDOW_ID:-}" ] || exit 0
exec "$HOME/.local/bin/input-source" --ghostty-window "$AEROSPACE_WINDOW_ID"
