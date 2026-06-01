#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift build --package-path apps/macos

if [ -x ".toolchains/gradle-8.10.2/bin/gradle" ]; then
  scripts/build-android-apk.sh
elif command -v java >/dev/null 2>&1 && [ -x "apps/android/gradlew" ]; then
  (cd apps/android && ./gradlew :app:assembleDebug)
elif command -v java >/dev/null 2>&1 && command -v gradle >/dev/null 2>&1; then
  (cd apps/android && gradle :app:assembleDebug)
else
  echo "Skipping Android build: Java runtime plus Gradle/Gradle wrapper not available."
fi
