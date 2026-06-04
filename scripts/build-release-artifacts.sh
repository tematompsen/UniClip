#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
RELEASE_DIR="$ROOT/dist/release"
MAC_ZIP="$RELEASE_DIR/UniClip-macOS-$VERSION.zip"
ANDROID_APK="$ROOT/dist/android/UniClip-Android-$VERSION-release.apk"
ANDROID_RELEASE_APK="$RELEASE_DIR/UniClip-Android-$VERSION-release.apk"

mkdir -p "$RELEASE_DIR"
rm -f "$MAC_ZIP" "$ANDROID_RELEASE_APK" "$RELEASE_DIR/SHA256SUMS.txt"

"$ROOT/scripts/build-macos-app.sh" >/dev/null
codesign --force --deep --sign - "$ROOT/dist/macOS/UniClip.app" >/dev/null
codesign --verify --deep --strict "$ROOT/dist/macOS/UniClip.app"
ditto -c -k --keepParent "$ROOT/dist/macOS/UniClip.app" "$MAC_ZIP"

"$ROOT/scripts/build-android-release-apk.sh" >/dev/null
cp "$ANDROID_APK" "$ANDROID_RELEASE_APK"

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$MAC_ZIP")" "$(basename "$ANDROID_RELEASE_APK")" > SHA256SUMS.txt
)

echo "$MAC_ZIP"
echo "$ANDROID_RELEASE_APK"
echo "$RELEASE_DIR/SHA256SUMS.txt"
