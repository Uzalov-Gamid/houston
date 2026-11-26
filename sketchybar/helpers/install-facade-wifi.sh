#!/bin/bash
set -euo pipefail

helper_dir="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/.local/share/sketchybar/Facade Wi-Fi.app"
mkdir -p "$app/Contents/MacOS"
swiftc -O "$helper_dir/facade-wifi.swift" -o "$app/Contents/MacOS/FacadeWiFi"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>dev.uzalov.facade-wifi</string>
  <key>CFBundleName</key><string>Facade Wi-Fi</string>
  <key>CFBundleDisplayName</key><string>Facade Wi-Fi</string>
  <key>CFBundleExecutable</key><string>FacadeWiFi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>NSLocationUsageDescription</key>
  <string>Allow the Wi-Fi menu to display the connected network name and nearby networks. Location coordinates are not read or stored.</string>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify "$app"
