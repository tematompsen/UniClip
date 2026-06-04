# UniClip

Local-network clipboard bridge for Android and macOS.

- [Русская документация](README.ru.md)
- [English documentation](README.en.md)

## Overview

UniClip sends clipboard content from Android to macOS over a local home network. Android sends selected text or shared images. macOS receives the content, writes it to the system clipboard, and keeps recent clipboard history in a menu bar panel.

The app is built for a low-friction flow: add one or more Macs on Android once, then send content to all trusted Macs on the same LAN.

## Features

- LAN discovery with mDNS/Bonjour.
- Android selected-text sending.
- Android share-sheet sending for text and images.
- Sending to all trusted Macs.
- macOS menu bar receiver.
- macOS clipboard history with search.
- Configurable history size from 10 to 100 items.
- Global hotkey for history window, default `Option + V`.
- Text and PNG/JPEG image support.
- Automatic paste from history when macOS Accessibility permission is granted.

## Quick Build

```sh
scripts/build-macos-app.sh
scripts/build-android-apk.sh
```

Build artifacts:

- `dist/macOS/UniClip.app`
- `dist/android/UniClip-debug.apk`

Device-test artifacts are usually copied to:

- `builds/device-test/UniClip.app`
- `builds/device-test/UniClip-debug.apk`

## Status

UniClip is a working local prototype. Discovery, text transfer, image sharing, macOS clipboard history, and menu bar UI are implemented. Transport security and real pairing are still planned work.
