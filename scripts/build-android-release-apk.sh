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

VERSION_NAME="$(awk -F'"' '/versionName/ { print $2; exit }' "$ROOT/apps/android/app/build.gradle.kts")"
SECRETS_DIR="$ROOT/.secrets"
SIGNING_ENV="$SECRETS_DIR/android-release.env"
KEYSTORE_FILE="$SECRETS_DIR/uniclip-release.jks"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

if [ -f "$SIGNING_ENV" ]; then
  # shellcheck disable=SC1090
  source "$SIGNING_ENV"
  UNICLIP_RELEASE_KEY_PASSWORD="$UNICLIP_RELEASE_STORE_PASSWORD"
else
  UNICLIP_RELEASE_STORE_FILE="$KEYSTORE_FILE"
  UNICLIP_RELEASE_STORE_PASSWORD="$(openssl rand -hex 24)"
  UNICLIP_RELEASE_KEY_ALIAS="uniclip-release"
  UNICLIP_RELEASE_KEY_PASSWORD="$UNICLIP_RELEASE_STORE_PASSWORD"

  cat > "$SIGNING_ENV" <<ENV
UNICLIP_RELEASE_STORE_FILE="$UNICLIP_RELEASE_STORE_FILE"
UNICLIP_RELEASE_STORE_PASSWORD="$UNICLIP_RELEASE_STORE_PASSWORD"
UNICLIP_RELEASE_KEY_ALIAS="$UNICLIP_RELEASE_KEY_ALIAS"
UNICLIP_RELEASE_KEY_PASSWORD="$UNICLIP_RELEASE_KEY_PASSWORD"
ENV
  chmod 600 "$SIGNING_ENV"
fi

if [ ! -f "$UNICLIP_RELEASE_STORE_FILE" ]; then
  "$JAVA_HOME/bin/keytool" -genkeypair \
    -keystore "$UNICLIP_RELEASE_STORE_FILE" \
    -storepass "$UNICLIP_RELEASE_STORE_PASSWORD" \
    -alias "$UNICLIP_RELEASE_KEY_ALIAS" \
    -keypass "$UNICLIP_RELEASE_KEY_PASSWORD" \
    -keyalg RSA \
    -keysize 4096 \
    -validity 10000 \
    -dname "CN=UniClip, OU=UniClip, O=UniClip, L=Local, ST=Local, C=US"
fi

cd "$ROOT/apps/android"
"$GRADLE" :app:assembleRelease

UNSIGNED_APK="$ROOT/apps/android/app/build/outputs/apk/release/app-release-unsigned.apk"
ALIGNED_APK="$ROOT/dist/android/UniClip-Android-$VERSION_NAME-release-aligned.apk"
SIGNED_APK="$ROOT/dist/android/UniClip-Android-$VERSION_NAME-release.apk"
ZIPALIGN="$ANDROID_HOME_DIR/build-tools/35.0.0/zipalign"
APKSIGNER="$ANDROID_HOME_DIR/build-tools/35.0.0/apksigner"

mkdir -p "$ROOT/dist/android"
rm -f "$ALIGNED_APK" "$SIGNED_APK"

"$ZIPALIGN" -p -f 4 "$UNSIGNED_APK" "$ALIGNED_APK"
"$APKSIGNER" sign \
  --ks "$UNICLIP_RELEASE_STORE_FILE" \
  --ks-key-alias "$UNICLIP_RELEASE_KEY_ALIAS" \
  --ks-pass "pass:$UNICLIP_RELEASE_STORE_PASSWORD" \
  --key-pass "pass:$UNICLIP_RELEASE_KEY_PASSWORD" \
  --out "$SIGNED_APK" \
  "$ALIGNED_APK"
"$APKSIGNER" verify --verbose "$SIGNED_APK" >/dev/null

rm -f "$ALIGNED_APK"
echo "$SIGNED_APK"
