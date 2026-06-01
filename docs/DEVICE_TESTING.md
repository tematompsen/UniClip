# Device Testing

## Build

macOS app:

```sh
scripts/build-macos-app.sh
codesign --force --deep --sign - dist/macOS/UniClip.app
```

Android debug APK:

```sh
scripts/build-android-apk.sh
```

Artifacts:

- `dist/macOS/UniClip.app`
- `dist/android/UniClip-debug.apk`

## Install Android APK

Enable Android device debugging:

1. Enable Developer options.
2. Enable USB debugging.
3. Connect phone with USB.
4. Accept the computer trust prompt on the phone.

Install:

```sh
scripts/install-android-debug.sh
```

If `adb devices` shows `unauthorized`, unlock the phone and accept the prompt.

## Run macOS Receiver

For logs during prototype testing, run the app executable from Terminal:

```sh
dist/macOS/UniClip.app/Contents/MacOS/UniClip
```

Double-clicking `dist/macOS/UniClip.app` also starts the receiver, but the current prototype has no visible menu bar UI yet.

## End-To-End Text Test

1. Start macOS receiver.
2. Open UniClip on Android.
3. Tap `Scan`.
4. Add discovered Mac.
5. In any Android app, select text.
6. Tap `Send to Mac`.
7. On Mac, paste with `Cmd+V`.

## Local Mac Test

Without Android:

```sh
scripts/send-test-clip.swift "hello from test"
pbpaste
```

Expected output:

```text
hello from test
```

## Current Prototype Limits

- Transport is plain TCP/JSON.
- Pairing approval and encryption are not implemented yet.
- macOS receiver has a menu bar icon with a quit action, but no settings window yet.
