# UniClip Build and Device Testing

This document covers `.app` and `.apk` builds, device installation, and basic checks.

## Requirements

macOS:

- macOS 14+ for current bundle metadata;
- Swift toolchain;
- `iconutil`;
- Local Network permission if macOS asks on first launch.

Android:

- JDK;
- Android SDK;
- Gradle;
- Android device with USB debugging enabled.

Project includes a local Android toolchain provisioning script:

```sh
scripts/provision-android-toolchain.sh
```

## Quick Repository Check

```sh
scripts/check.sh
```

Run this before final builds.

## Build macOS

```sh
scripts/build-macos-app.sh
```

Output:

```text
dist/macOS/UniClip.app
```

Device-test artifact:

```sh
rm -rf builds/device-test/UniClip.app
mkdir -p builds/device-test
cp -R dist/macOS/UniClip.app builds/device-test/UniClip.app
codesign --force --deep --sign - builds/device-test/UniClip.app
codesign --verify --deep --strict builds/device-test/UniClip.app
```

## Build Android APK

```sh
scripts/build-android-apk.sh
```

Output:

```text
dist/android/UniClip-debug.apk
```

Device-test artifact:

```sh
mkdir -p builds/device-test
cp dist/android/UniClip-debug.apk builds/device-test/UniClip-debug.apk
```

## Release Artifacts

For GitHub Releases:

```sh
scripts/build-release-artifacts.sh
```

Output:

```text
dist/release/UniClip-macOS-0.1.0.zip
dist/release/UniClip-Android-0.1.0-release.apk
dist/release/SHA256SUMS.txt
```

Android release APK is signed with a local key from `.secrets/`. If the key does not exist, the script creates it automatically. Do not commit `.secrets/`; keep it separately if future release APKs must update already installed builds.

## Install Android APK

1. Open Android settings.
2. Enable Developer options.
3. Enable USB debugging.
4. Connect phone over USB.
5. Approve computer trust prompt on the phone.

Check:

```sh
adb devices
```

Install:

```sh
scripts/install-android-debug.sh
```

If `adb devices` shows `unauthorized`, unlock the phone and approve the prompt.

## Run macOS App

Normal launch:

```sh
open builds/device-test/UniClip.app
```

Launch with logs:

```sh
builds/device-test/UniClip.app/Contents/MacOS/UniClip
```

The app appears in the macOS menu bar. It has no main Dock window.

## End-to-End Text Test

1. Start UniClip on the Mac.
2. Open UniClip on Android.
3. Tap `Scan`.
4. Add discovered Mac.
5. Open any Android app with text.
6. Select text.
7. Choose UniClip from the context menu.
8. Paste on the Mac with `Cmd + V`.

Expected:

- Android shows `✅`;
- Mac pasteboard contains sent text;
- item appears in UniClip history.

## End-to-End Image Test

1. Start UniClip on the Mac.
2. Make sure the Mac is in Android trusted list.
3. Select an image in Android Gallery/Photos.
4. Tap Share.
5. Choose UniClip.
6. Paste on the Mac into an app that accepts images.

Expected:

- Android shows `✅`;
- image is available in macOS pasteboard;
- item appears in history as `Изображение`.

Limits:

- Android sends images up to `12 MB`;
- macOS accepts total payload up to `20 MB`.

## Local Test Without Android

```sh
scripts/send-test-clip.swift "hello from local test"
pbpaste
```

Expected:

```text
hello from local test
```

## macOS History Test

1. Copy several different texts on the Mac.
2. Open UniClip from menu bar icon or hotkey.
3. Check order: newest item first.
4. Type a search query.
5. Click an item.
6. Check that it is copied and the panel closes.

## Hotkey Test

1. Open UniClip.
2. Click `Настройки...`.
3. Click the shortcut button.
4. Enter a new shortcut.
5. Close the panel.
6. Test the new shortcut.

Default:

```text
Option + V
```

## Auto-Paste Test

1. Grant UniClip Accessibility permission if macOS asks.
2. Open a text field in any app.
3. Open UniClip history.
4. Select an item.

Expected:

- item is copied to pasteboard;
- UniClip panel closes;
- text is pasted into the previous active app.

If permission is missing, UniClip should open Accessibility settings and show an alert.

## Energy Testing

On Mac:

- Activity Monitor -> CPU;
- Activity Monitor -> Energy;
- verify UniClip does not keep high CPU while idle;
- after sleep/wake, verify receiver still works.

On Android:

- system battery stats;
- verify Scan is stopped when not needed;
- verify app is not kept active in foreground unnecessarily.

## Common Issues

Mac not discovered:

- both devices must be on the same network;
- check macOS firewall;
- check that UniClip is running on Mac;
- tap `Stop`, then `Scan` on Android.

Android shows send error:

- Mac IP may have changed;
- remove Mac from trusted list and add again;
- check port `47191`;
- check that macOS app is not closed.

History click does not paste:

- check Accessibility permission;
- check that previous app accepts paste;
- try manual `Cmd + V` first.

Image does not paste:

- check size under `12 MB`;
- try PNG or JPEG;
- check target Mac app image paste support.
