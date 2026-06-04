# UniClip Prototype Protocol

- [Русский](#русский)
- [English](#english)

## Русский

Текущий протокол временный. Он нужен для проверки LAN discovery и передачи данных Android -> macOS до внедрения pairing и authenticated encryption.

### Service Discovery

macOS публикует Bonjour service:

- service type: `_uniclip._tcp.`
- domain: `local.`
- port: `47191`
- TXT:
  - `version=1`
  - `device=mac`
  - `name=<host name>`

Android ищет этот service через `NsdManager`.

### Transport

Android открывает TCP connection к Mac и отправляет один newline-delimited JSON object.

Framing:

```text
<json>\n
```

macOS читает данные до `\n` или закрытия connection.

Текущий максимальный размер сообщения на macOS:

```text
20 MB
```

### Payload

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

Поля:

- `protocolVersion` - версия протокола. Сейчас `1`.
- `clipId` - уникальный ID отправки. macOS использует его для защиты от дублей в рамках процесса.
- `sourceDeviceId` - ID Android-устройства для диагностики.
- `sourceDeviceName` - человекочитаемое имя Android-устройства.
- `contentType` - MIME type.
- `createdAt` - время создания payload.
- `ttlSeconds` - желаемый TTL. Сейчас не используется для строгой проверки.
- `payload` - текст или base64 bytes.

### Text

Для текста:

```json
{
  "contentType": "text/plain",
  "payload": "hello"
}
```

`payload` содержит plain UTF-8 text.

### Images

Для изображений:

```json
{
  "contentType": "image/png",
  "payload": "<base64>"
}
```

Поддерживаемые типы на macOS:

- `image/png`
- `image/jpeg`
- `image/jpg`

Android ограничивает размер исходного изображения до `12 MB`.

### Response

macOS отвечает одним newline-delimited JSON object:

```json
{
  "status": "ok"
}
```

Варианты:

- `ok` - payload принят и записан в pasteboard.
- `duplicate` - `clipId` уже был обработан.
- `error` - payload отклонен.

Error response:

```json
{
  "status": "error",
  "detail": "Payload too large"
}
```

Android показывает `✅` для `ok` и `duplicate`.

### Security Gap

Текущий транспорт plain TCP. Его нельзя считать защищенным.

Риски:

- LAN device может spoof mDNS service.
- LAN attacker может читать payload.
- LAN attacker может отправлять payload на Mac.
- Нет cryptographic identity.
- Нет replay protection кроме in-memory `clipId` дедупликации.

Перед production нужны:

- explicit macOS pairing approval;
- persistent device keys;
- peer public key pinning;
- authenticated encryption;
- nonce/timestamp/sequence validation;
- payload size and MIME validation;
- pairing rate limits.

## English

Current protocol is temporary. It validates LAN discovery and Android -> macOS delivery before pairing and authenticated encryption are implemented.

### Service Discovery

macOS publishes Bonjour service:

- service type: `_uniclip._tcp.`
- domain: `local.`
- port: `47191`
- TXT:
  - `version=1`
  - `device=mac`
  - `name=<host name>`

Android discovers this service through `NsdManager`.

### Transport

Android opens a TCP connection to the Mac and sends one newline-delimited JSON object.

Framing:

```text
<json>\n
```

macOS reads data until `\n` or connection close.

Current max macOS message size:

```text
20 MB
```

### Payload

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

Fields:

- `protocolVersion` - protocol version. Currently `1`.
- `clipId` - unique send ID. macOS uses it for duplicate detection within the process.
- `sourceDeviceId` - Android device ID for diagnostics.
- `sourceDeviceName` - human-readable Android device name.
- `contentType` - MIME type.
- `createdAt` - payload creation time.
- `ttlSeconds` - desired TTL. Not strictly enforced yet.
- `payload` - text or base64 bytes.

### Text

For text:

```json
{
  "contentType": "text/plain",
  "payload": "hello"
}
```

`payload` contains plain UTF-8 text.

### Images

For images:

```json
{
  "contentType": "image/png",
  "payload": "<base64>"
}
```

Supported macOS types:

- `image/png`
- `image/jpeg`
- `image/jpg`

Android limits source image size to `12 MB`.

### Response

macOS responds with one newline-delimited JSON object:

```json
{
  "status": "ok"
}
```

Variants:

- `ok` - payload accepted and written to pasteboard.
- `duplicate` - `clipId` was already processed.
- `error` - payload rejected.

Error response:

```json
{
  "status": "error",
  "detail": "Payload too large"
}
```

Android shows `✅` for `ok` and `duplicate`.

### Security Gap

Current transport is plain TCP. It must not be treated as secure.

Risks:

- LAN device can spoof mDNS service.
- LAN attacker can read payload.
- LAN attacker can send payload to Mac.
- No cryptographic identity.
- No replay protection except in-memory `clipId` deduplication.

Required before production:

- explicit macOS pairing approval;
- persistent device keys;
- peer public key pinning;
- authenticated encryption;
- nonce/timestamp/sequence validation;
- payload size and MIME validation;
- pairing rate limits.
