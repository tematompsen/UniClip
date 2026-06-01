# UniClip Prototype Protocol

This protocol is temporary. It exists to validate LAN discovery and Android-to-macOS text delivery before authenticated encryption and pairing are implemented.

## Service Discovery

macOS advertises:

- service type: `_uniclip._tcp.`
- port: `47191`
- TXT:
  - `version=1`
  - `device=mac`
  - `name=<host name>`

## Payload

Android sends one newline-delimited JSON object over a TCP connection.

```json
{
  "protocolVersion": 1,
  "clipId": "uuid",
  "sourceDeviceId": "android-build-id",
  "sourceDeviceName": "Google Pixel",
  "contentType": "text/plain",
  "createdAt": "2026-06-01T19:00:00Z",
  "ttlSeconds": 300,
  "payload": "Text to paste"
}
```

For `text/plain`, `payload` is plain UTF-8 text.

For `image/*`, `payload` is base64-encoded image bytes. Current tested target types:

- `image/png`
- `image/jpeg`

macOS responds with one newline-delimited JSON object:

```json
{
  "status": "ok"
}
```

## Security Gap

Current prototype transport is plain TCP. It must not be used for real clipboard data outside development.

Required before real use:

- explicit macOS pairing approval.
- persistent device keys.
- peer key pinning.
- authenticated encryption.
- replay protection.
- payload size limits.
