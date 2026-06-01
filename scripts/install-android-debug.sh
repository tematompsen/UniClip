#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="$ROOT/dist/android/UniClip-debug.apk"

if [ ! -f "$APK" ]; then
  "$ROOT/scripts/build-android-apk.sh"
fi

export ANDROID_HOME="$ROOT/.toolchains/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

adb devices
adb install -r "$APK"
