#!/bin/bash
set -euo pipefail
helper_dir="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/.local/share/sketchybar/Facade Panel.app"
mkdir -p "$app/Contents/MacOS"
swiftc -O "$helper_dir/facade-panel.swift" -o "$app/Contents/MacOS/FacadePanel"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>dev.uzalov.facade-panel</string>
  <key>CFBundleDisplayName</key><string>Facade Panel</string>
  <key>CFBundleExecutable</key><string>FacadePanel</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify "$app"
