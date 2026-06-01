# UniClip

Secure local-network clipboard bridge between Android and macOS.

UniClip lets an Android device send selected text and shared images/files to all trusted online Mac computers in the same home network. macOS receives the content and places it into the system clipboard for normal `Cmd+V` paste.

## Product Direction

- Android does not rely on background clipboard reading.
- Text sending uses Android selected-text actions.
- Images and files use Android share sheet.
- macOS runs as a menu bar receiver.
- Devices are discovered on LAN with mDNS/Bonjour.
- Pairing requires explicit approval on macOS.
- Transfer is allowed only between trusted devices.
- Default sending target is all trusted online Macs.

## Current State

Development baseline:

- macOS SwiftPM receiver prototype in `apps/macos`.
- Android Kotlin/Compose sender scaffold in `apps/android`.
- Prototype protocol in `protocol`.

## Local Prototype

Run macOS receiver:

```sh
scripts/run-macos-receiver.sh
```

Send test text from same Mac:

```sh
scripts/send-test-clip.swift "hello from UniClip"
```

Run checks:

```sh
scripts/check.sh
```

Android build requires JDK and Android SDK.
