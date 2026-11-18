#!/bin/bash
# Builds build/Switch.app. Pass "run" to relaunch it afterwards.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
app=build/Switch.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/Switch "$app/Contents/MacOS/Switch"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"

if [ "${1:-}" = "run" ]; then
    pkill -x Switch || true
    open "$app"
fi
