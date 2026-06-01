# UniClip Implementation Plan

## Goal

Build a secure local-network clipboard bridge:

- Android sends selected text and shared images/files.
- macOS receives content and writes it to `NSPasteboard`.
- One Android phone can send to multiple trusted online Macs.
- No cloud service.
- No account.
- No background Android clipboard scraping.

## Platform Constraints

Android 10+ restricts clipboard reads for background apps. A normal Android app cannot reliably observe every clipboard change while running in the background. UniClip will avoid that dependency.

Supported Android send paths:

- Selected text action: user selects text, taps `Send to Mac`.
- Share sheet: user shares text, links, images, or files to UniClip.
- Optional later mode: Android input method for automatic clipboard-like workflows.

Supported macOS receive path:

- Menu bar app receives payloads from trusted Android devices.
- App writes received text/images to system pasteboard.
- User pastes with `Cmd+V`.

## MVP Scope

### Android

- Kotlin app.
- Jetpack Compose UI.
- mDNS discovery of UniClip Mac receivers.
- Device pairing request flow.
- Trusted computers list.
- `ACTION_PROCESS_TEXT` receiver for selected text.
- `ACTION_SEND` receiver for text, links, and images.
- Send to all trusted online Macs by default.
- Notification after send success/failure.
- Local encrypted storage for trusted peer metadata.

### macOS

- Swift/SwiftUI menu bar app.
- Bonjour/mDNS advertise `_uniclip._tcp`.
- Pairing approval dialog.
- Trusted phones list.
- Receive text payloads and write plain text to pasteboard.
- Receive image payloads and write image data to pasteboard.
- Notification after receive.
- Keychain storage for device identity and trusted peers.

### Security

- Discovery is not trust.
- Unknown devices can only request pairing.
- macOS user must explicitly allow pairing.
- Pairing requests expire.
- Pairing attempts are rate limited.
- Each device has a persistent asymmetric key pair.
- Every transfer uses authenticated encrypted transport.
- Payloads include nonce, timestamp, sequence, source device id, and content id.
- Duplicate content ids are ignored to prevent loops.

## Non-Goals For MVP

- Cloud sync.
- Accounts.
- Full clipboard history.
- Background Android clipboard monitoring.
- Automatic Android-to-Mac sync after every copy.
- Editing clipboard content before send.
- Windows/Linux clients.
- WAN access.

## Pairing Flow

1. macOS app is running and advertises itself on LAN.
2. Android user opens `Add computers`.
3. Android scans LAN and shows available Macs.
4. User taps `Connect`.
5. Mac shows request:
   - Android device name.
   - Android model.
   - public key fingerprint.
   - request age.
6. Mac user taps `Allow` or `Deny`.
7. If allowed, both sides store trusted peer identities.
8. Android adds Mac to trusted computers.
9. Future sends go to that Mac automatically when online.

## Sending Flow

### Selected Text

1. User selects text in Android app.
2. User taps `Send to Mac`.
3. UniClip receives `ACTION_PROCESS_TEXT`.
4. UniClip lists trusted online Macs.
5. UniClip sends text to all trusted online Macs.
6. Each Mac writes text to pasteboard.

### Image Or File

1. User opens Android share sheet.
2. User selects `Send to Mac`.
3. UniClip receives URI with temporary permission.
4. UniClip validates MIME type and size.
5. UniClip sends to all trusted online Macs.
6. Each Mac validates payload and writes supported image data to pasteboard.

## Routing Rules

Default route:

- Send to all trusted online Macs.

Failure behavior:

- If no trusted Mac is online, show failure notification.
- Text may be queued for a short retry window later.
- Images/files are not queued by default.

User settings:

- Send to all trusted online Macs.
- Ask before sending images/files.
- Wi-Fi only.
- Known networks only.
- Max text size.
- Max image/file size.
- Remove trusted Mac.

## Network Design

### Discovery

- mDNS/Bonjour service type: `_uniclip._tcp`.
- Service TXT records:
  - app version.
  - device type.
  - device id hash.
  - protocol version.
  - display name.

Discovery only reveals availability. It does not grant access.

### Transport

MVP target:

- TCP on LAN.
- TLS 1.3 or Noise-style authenticated channel.
- Pinned peer public keys after pairing.

Message categories:

- `pairing_request`
- `pairing_response`
- `hello`
- `clip_offer`
- `clip_payload`
- `ack`
- `error`

## Data Model

### Device

```json
{
  "device_id": "uuid",
  "display_name": "MacBook Pro",
  "device_type": "mac",
  "public_key_fingerprint": "A8:3F:91:22",
  "trusted": true,
  "last_seen": "2026-06-01T19:00:00Z"
}
```

### Clip Metadata

```json
{
  "clip_id": "uuid",
  "source_device_id": "uuid",
  "content_type": "text/plain",
  "created_at": "2026-06-01T19:00:00Z",
  "ttl_seconds": 300,
  "payload_size": 1234
}
```

## Build Phases

### Phase 0: Planning Baseline

- Define product constraints.
- Define pairing flow.
- Define routing model.
- Define MVP scope.
- Initialize repository.

### Phase 1: macOS Receiver Prototype

- Create Swift menu bar app.
- Generate local device identity.
- Advertise mDNS service.
- Accept local test payload.
- Write text to pasteboard.

### Phase 2: Android Sender Prototype

- Create Kotlin/Compose app.
- Discover mDNS services.
- Show available Macs.
- Implement selected-text receiver.
- Send plain text to prototype Mac receiver.

### Phase 3: Pairing And Trust

- Add pairing request/approval.
- Store peer identity.
- Reject untrusted payloads.
- Add trusted devices UI.

### Phase 4: Secure Transport

- Add authenticated encrypted channel.
- Add nonces, timestamps, sequence numbers.
- Add replay protection.
- Add payload size limits.

### Phase 5: Share Sheet Media

- Add Android `ACTION_SEND` for images/files.
- Stream URI payload.
- Validate image MIME and size.
- Write image to macOS pasteboard.

### Phase 6: Polish And Reliability

- Notifications.
- Offline handling.
- Retry logic for small text.
- Settings screens.
- Logging and diagnostics.
- App signing preparation.

## Test Plan

### Unit Tests

- Device trust store.
- Routing rules.
- Message encoding/decoding.
- Replay protection.
- Payload validation.

### Integration Tests

- Android discovers Mac.
- Pairing approval stores trust.
- Untrusted sender is rejected.
- Text is delivered to all trusted online Macs.
- Offline Mac does not block other delivery.
- Duplicate clip id is ignored.

### Manual Tests

- Select text in browser and send.
- Share image from gallery.
- Send to two Macs at once.
- Remove Mac and verify it no longer receives.
- Restart apps and verify trusted devices persist.

## Open Decisions

- Exact secure transport library/protocol.
- Minimum Android version.
- Minimum macOS version.
- Whether to support queued text delivery in MVP.
- Whether to support file payloads beyond images in MVP.
