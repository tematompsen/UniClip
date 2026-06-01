#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/dist/macOS/UniClip.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"

swift build --package-path "$ROOT/apps/macos" -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS"

cp "$ROOT/apps/macos/.build/release/uniclip-mac" "$MACOS/UniClip"
cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>UniClip</string>
  <key>CFBundleIdentifier</key>
  <string>dev.uniclip.mac</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>UniClip</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSLocalNetworkUsageDescription</key>
  <string>UniClip uses the local network to receive clipboard content from trusted Android devices.</string>
</dict>
</plist>
PLIST

echo "$APP_DIR"
