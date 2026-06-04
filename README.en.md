# UniClip

UniClip is a local-network clipboard bridge between Android and macOS.

The Android app sends selected text or an image through Android system actions. The macOS app receives the payload, writes it to the system clipboard, and exposes recent clipboard history from the menu bar.

## Features

- macOS receiver discovery on LAN through mDNS/Bonjour.
- Multiple Mac receivers can be added to the Android trusted list.
- Text sending from Android selected-text actions.
- Text and image sending through the Android share sheet.
- Sending to all trusted online Macs.
- Text and PNG/JPEG receiving on macOS.
- Writing received content to `NSPasteboard`.
- macOS clipboard history.
- Search in history.
- Configurable history size from 10 to 100 items.
- Global history-window hotkey. Default: `Option + V`.
- Paste selected history item into the previous active app when macOS Accessibility allows it.
- macOS menu bar icon.

## Current Status

Project is a working prototype.

Implemented:

- macOS app in Swift/AppKit.
- Android app in Kotlin/Jetpack Compose.
- LAN discovery.
- Text and image transfer.
- macOS clipboard history.
- `.app` and debug `.apk` builds.

Not production-ready:

- Transport is plain TCP + JSON.
- Real cryptographic pairing is not implemented.
- No end-to-end encryption yet.
- Android trust list currently stores selected Mac endpoints locally.
- Protocol may change.

## Project Layout

```text
apps/
  android/                Android app
  macos/                  macOS app
docs/                     Additional documentation
icons/                    Source app icon
protocol/                 Current protocol description
scripts/                  Build, icon generation, test commands
```

## macOS App

Path: `apps/macos`.

Main parts:

- `main.swift` - TCP receiver, Bonjour advertising, status bar item, history panel, paste automation.
- `ClipboardHistory.swift` - `NSPasteboard` monitoring, deduplication, history limit.
- `HistoryPopoverController.swift` - history and settings UI.
- `HotKey.swift` - global hotkey registration.

The macOS app runs as an accessory/menu bar app. The history panel opens from the menu bar icon or global hotkey.

## Android App

Path: `apps/android`.

Main parts:

- `MainActivity.kt` - Mac discovery screen and trusted-device list.
- `MacDiscovery.kt` - Android NSD discovery for `_uniclip._tcp.`.
- `TrustRepository.kt` - local storage for added Macs.
- `ClipSender.kt` - JSON message sender for all trusted Macs.
- `ProcessTextActivity.kt` - selected-text sender.
- `ShareReceiverActivity.kt` - Android share intent receiver for text/images.

## Build

macOS:

```sh
scripts/build-macos-app.sh
```

Android:

```sh
scripts/build-android-apk.sh
```

Release artifacts for GitHub Releases:

```sh
scripts/build-release-artifacts.sh
```

Both scripts write artifacts to `dist`:

- `dist/macOS/UniClip.app`
- `dist/android/UniClip-debug.apk`
- `dist/release/UniClip-macOS-0.1.0.zip`
- `dist/release/UniClip-Android-0.1.0-release.apk`
- `dist/release/SHA256SUMS.txt`

Android release signing key is generated locally in `.secrets/` and is not committed. Keep it if you need future APK builds to install over previous release builds.

Device testing usually uses:

- `builds/device-test/UniClip.app`
- `builds/device-test/UniClip-debug.apk`

If Android toolchain is not provisioned locally yet:

```sh
scripts/provision-android-toolchain.sh
```

## Install and Test

1. Build the macOS app.
2. Run `UniClip.app` on the Mac.
3. Build the Android APK.
4. Install the APK on the phone.
5. Connect the Mac and Android device to the same Wi-Fi network.
6. Open UniClip on Android.
7. Tap `Scan`.
8. Add the discovered Mac to the trusted list.
9. Select text in any Android app and choose UniClip from the context menu.
10. On the Mac, paste with `Cmd + V` or select the item from UniClip history.

Local test without Android:

```sh
scripts/send-test-clip.swift "hello from UniClip"
pbpaste
```

Expected output:

```text
hello from UniClip
```

## macOS Clipboard History

History is stored in process memory. Restarting the app clears it.

Supported:

- text;
- images from `NSPasteboard` (`TIFF`, `PNG`);
- search;
- SHA-256 deduplication;
- 10-100 item limit.

## Automatic Paste

When a user selects a history item, UniClip copies it to the clipboard and tries to send `Cmd + V` to the previous active application.

macOS may require Accessibility permission. If permission is missing, UniClip opens system settings and shows an alert.

## Protocol

Current protocol is documented in [protocol/README.md](protocol/README.md).

Summary:

- service type: `_uniclip._tcp.`
- port: `47191`
- payload: newline-delimited JSON
- text: plain UTF-8 string in `payload`
- image: base64 bytes in `payload`
- response: JSON with `status`

## Security

Current implementation is for local prototyping. Do not send sensitive content through an untrusted network.

Required before production:

- pairing with explicit macOS approval;
- persistent device keys;
- peer key pinning;
- authenticated encryption;
- replay protection;
- strict size and MIME limits;
- pairing rate limits.

## Useful Commands

```sh
scripts/check.sh
scripts/build-macos-app.sh
scripts/build-android-apk.sh
scripts/install-android-debug.sh
scripts/send-test-clip.swift "test"
```

## Additional Docs

- [Архитектура RU](docs/ARCHITECTURE.ru.md)
- [Сборка и тестирование RU](docs/DEVICE_TESTING.ru.md)
- [Architecture EN](docs/ARCHITECTURE.en.md)
- [Build and testing EN](docs/DEVICE_TESTING.en.md)
