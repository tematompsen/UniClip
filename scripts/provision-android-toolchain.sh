#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLCHAINS="$ROOT/.toolchains"
JDK_DIR="$TOOLCHAINS/jdk-17"
ANDROID_HOME_DIR="$TOOLCHAINS/android-sdk"
GRADLE_DIR="$TOOLCHAINS/gradle-8.10.2"
DOWNLOADS="$TOOLCHAINS/downloads"

mkdir -p "$DOWNLOADS" "$ANDROID_HOME_DIR/cmdline-tools"

if [ ! -x "$JDK_DIR/Contents/Home/bin/java" ]; then
  echo "Installing Temurin JDK 17..."
  JDK_ARCHIVE="$DOWNLOADS/temurin-jdk17-mac-aarch64.tar.gz"
  curl -L "https://api.adoptium.net/v3/binary/latest/17/ga/mac/aarch64/jdk/hotspot/normal/eclipse" -o "$JDK_ARCHIVE"
  rm -rf "$JDK_DIR"
  mkdir -p "$JDK_DIR"
  tar -xzf "$JDK_ARCHIVE" -C "$JDK_DIR" --strip-components=1
fi

export JAVA_HOME="$JDK_DIR/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

if [ ! -x "$ANDROID_HOME_DIR/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "Installing Android command line tools..."
  CMDLINE_URL="$(curl -fsSL https://developer.android.com/studio | grep -Eo 'https://dl.google.com/android/repository/commandlinetools-mac-[0-9]+_latest.zip' | head -n 1)"
  if [ -z "$CMDLINE_URL" ]; then
    echo "Could not find Android command line tools URL." >&2
    exit 1
  fi
  CMDLINE_ARCHIVE="$DOWNLOADS/android-cmdline-tools.zip"
  curl -L "$CMDLINE_URL" -o "$CMDLINE_ARCHIVE"
  rm -rf "$ANDROID_HOME_DIR/cmdline-tools/latest" "$ANDROID_HOME_DIR/cmdline-tools/cmdline-tools"
  unzip -q "$CMDLINE_ARCHIVE" -d "$ANDROID_HOME_DIR/cmdline-tools"
  mv "$ANDROID_HOME_DIR/cmdline-tools/cmdline-tools" "$ANDROID_HOME_DIR/cmdline-tools/latest"
fi

export ANDROID_HOME="$ANDROID_HOME_DIR"
export ANDROID_SDK_ROOT="$ANDROID_HOME_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

mkdir -p "$HOME/.android"
touch "$HOME/.android/repositories.cfg"

set +o pipefail
yes | sdkmanager --licenses >/dev/null
set -o pipefail
sdkmanager \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0"

if [ ! -x "$GRADLE_DIR/bin/gradle" ]; then
  echo "Installing Gradle 8.10.2..."
  GRADLE_ARCHIVE="$DOWNLOADS/gradle-8.10.2-bin.zip"
  curl -L "https://services.gradle.org/distributions/gradle-8.10.2-bin.zip" -o "$GRADLE_ARCHIVE"
  rm -rf "$GRADLE_DIR"
  unzip -q "$GRADLE_ARCHIVE" -d "$TOOLCHAINS"
fi

cat > "$ROOT/apps/android/local.properties" <<EOF
sdk.dir=$ANDROID_HOME_DIR
EOF

cat <<EOF
Android toolchain ready.
JAVA_HOME=$JAVA_HOME
ANDROID_HOME=$ANDROID_HOME
GRADLE=$GRADLE_DIR/bin/gradle
ADB=$ANDROID_HOME/platform-tools/adb
EOF
