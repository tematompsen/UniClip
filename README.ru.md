# UniClip

UniClip - локальный мост буфера обмена между Android и macOS в рамках одной домашней сети.

Android-приложение отправляет выделенный текст или изображение через системное меню "Поделиться". macOS-приложение принимает данные, кладет их в системный буфер обмена и показывает историю последних элементов в меню в верхней панели.

## Возможности

- Поиск macOS-приемников в локальной сети через mDNS/Bonjour.
- Добавление нескольких Mac в список доверенных устройств на Android.
- Отправка текста из Android через действие для выделенного текста.
- Отправка текста и изображений через Android share sheet.
- Отправка сразу на все доверенные Mac в сети.
- Прием текста и PNG/JPEG на macOS.
- Запись полученного контента в `NSPasteboard`.
- История буфера обмена на macOS.
- Поиск по истории.
- Настройка размера истории от 10 до 100 элементов.
- Глобальная горячая клавиша вызова окна истории. По умолчанию `Option + V`.
- Вставка выбранного элемента истории в предыдущее активное приложение, если macOS разрешает Accessibility.
- Иконка приложения в строке меню macOS.

## Текущий статус

Проект находится в стадии рабочего прототипа.

Готово:

- macOS-приложение на Swift/AppKit.
- Android-приложение на Kotlin/Jetpack Compose.
- LAN discovery.
- Передача текста и изображений.
- История буфера на macOS.
- Сборка `.app` и debug `.apk`.

Не готово для production:

- Транспорт пока plain TCP + JSON.
- Реальное cryptographic pairing не реализовано.
- Нет end-to-end encryption.
- Trust list на Android сейчас хранит выбранные Mac как локальный список адресов.
- Протокол может измениться.

## Структура проекта

```text
apps/
  android/                Android-приложение
  macos/                  macOS-приложение
docs/                     Дополнительная документация
icons/                    Исходная иконка приложения
protocol/                 Описание текущего протокола
scripts/                  Сборка, генерация иконок, тестовые команды
```

## macOS-приложение

Путь: `apps/macos`.

Основные части:

- `main.swift` - приемник TCP, Bonjour advertising, status bar item, окно истории, авто-вставка.
- `ClipboardHistory.swift` - мониторинг `NSPasteboard`, дедупликация, лимит истории.
- `HistoryPopoverController.swift` - UI истории и настроек.
- `HotKey.swift` - глобальная горячая клавиша.

macOS-приложение работает как accessory/menu bar app. Окно истории открывается по клику на иконку в верхней панели или по горячей клавише.

## Android-приложение

Путь: `apps/android`.

Основные части:

- `MainActivity.kt` - экран поиска Mac и список доверенных устройств.
- `MacDiscovery.kt` - поиск `_uniclip._tcp.` через Android NSD.
- `TrustRepository.kt` - локальное хранение добавленных Mac.
- `ClipSender.kt` - отправка JSON-сообщения на все доверенные Mac.
- `ProcessTextActivity.kt` - отправка выделенного текста.
- `ShareReceiverActivity.kt` - прием Android share intent для текста/изображений.

## Сборка

macOS:

```sh
scripts/build-macos-app.sh
```

Android:

```sh
scripts/build-android-apk.sh
```

Оба скрипта кладут результат в `dist`:

- `dist/macOS/UniClip.app`
- `dist/android/UniClip-debug.apk`

Для тестов на устройстве обычно используются:

- `builds/device-test/UniClip.app`
- `builds/device-test/UniClip-debug.apk`

Если Android toolchain еще не установлен локально:

```sh
scripts/provision-android-toolchain.sh
```

## Установка и тест

1. Собери macOS-приложение.
2. Запусти `UniClip.app` на Mac.
3. Собери Android APK.
4. Установи APK на телефон.
5. Подключи Mac и Android к одной Wi-Fi сети.
6. На Android открой UniClip.
7. Нажми `Scan`.
8. Добавь найденный Mac в trusted list.
9. Выдели текст в любом Android-приложении и выбери UniClip в контекстном меню.
10. На Mac вставь через `Cmd + V` или выбери элемент в истории UniClip.

Локальная проверка без Android:

```sh
scripts/send-test-clip.swift "hello from UniClip"
pbpaste
```

Ожидаемый результат:

```text
hello from UniClip
```

## История буфера на macOS

История хранится в памяти процесса. После перезапуска приложения список очищается.

Поддерживается:

- текст;
- изображения из `NSPasteboard` (`TIFF`, `PNG`);
- поиск;
- дедупликация по SHA-256;
- лимит 10-100 элементов.

## Автоматическая вставка

Когда пользователь выбирает элемент истории, UniClip копирует его в буфер обмена и пытается отправить `Cmd + V` в предыдущее активное приложение.

Для этого macOS может запросить Accessibility permission. Если разрешения нет, UniClip откроет системные настройки и покажет предупреждение.

## Протокол

Текущий протокол описан в [protocol/README.md](protocol/README.md).

Кратко:

- service type: `_uniclip._tcp.`
- port: `47191`
- payload: newline-delimited JSON
- text: plain UTF-8 string in `payload`
- image: base64 bytes in `payload`
- response: JSON with `status`

## Безопасность

Текущая реализация нужна для локального прототипирования. Не отправляй чувствительные данные через недоверенную сеть.

Перед production нужны:

- pairing с подтверждением на macOS;
- постоянные ключи устройств;
- pinning ключей;
- authenticated encryption;
- replay protection;
- строгие лимиты размера и MIME;
- rate limiting для попыток pairing.

## Полезные команды

```sh
scripts/check.sh
scripts/build-macos-app.sh
scripts/build-android-apk.sh
scripts/install-android-debug.sh
scripts/send-test-clip.swift "test"
```

## Дополнительные документы

- [Архитектура RU](docs/ARCHITECTURE.ru.md)
- [Сборка и тестирование RU](docs/DEVICE_TESTING.ru.md)
- [Architecture EN](docs/ARCHITECTURE.en.md)
- [Build and testing EN](docs/DEVICE_TESTING.en.md)
