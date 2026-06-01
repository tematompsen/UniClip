#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAVA_HOME_DIR="$ROOT/.toolchains/jdk-17/Contents/Home"
ANDROID_HOME_DIR="$ROOT/.toolchains/android-sdk"
GRADLE="$ROOT/.toolchains/gradle-8.10.2/bin/gradle"

if [ ! -x "$JAVA_HOME_DIR/bin/java" ] || [ ! -x "$ANDROID_HOME_DIR/platform-tools/adb" ] || [ ! -x "$GRADLE" ]; then
  "$ROOT/scripts/provision-android-toolchain.sh"
fi

export JAVA_HOME="$JAVA_HOME_DIR"
export ANDROID_HOME="$ANDROID_HOME_DIR"
export ANDROID_SDK_ROOT="$ANDROID_HOME_DIR"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

cd "$ROOT/apps/android"
"$GRADLE" :app:assembleDebug

mkdir -p "$ROOT/dist/android"
cp "$ROOT/apps/android/app/build/outputs/apk/debug/app-debug.apk" "$ROOT/dist/android/UniClip-debug.apk"
echo "$ROOT/dist/android/UniClip-debug.apk"
