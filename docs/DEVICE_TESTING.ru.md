# Сборка и тестирование UniClip

Документ описывает сборку `.app` и `.apk`, установку на устройства и базовые проверки.

## Требования

macOS:

- macOS 14+ для текущего bundle metadata;
- Swift toolchain;
- `iconutil`;
- права Local Network при первом запуске, если macOS запросит их.

Android:

- JDK;
- Android SDK;
- Gradle;
- Android device с включенным USB debugging.

В проекте есть скрипт локального provisioning Android toolchain:

```sh
scripts/provision-android-toolchain.sh
```

## Быстрая проверка репозитория

```sh
scripts/check.sh
```

Скрипт проверяет доступные части проекта и должен выполняться перед финальной сборкой.

## Сборка macOS

```sh
scripts/build-macos-app.sh
```

Результат:

```text
dist/macOS/UniClip.app
```

Для device-test артефакта:

```sh
rm -rf builds/device-test/UniClip.app
mkdir -p builds/device-test
cp -R dist/macOS/UniClip.app builds/device-test/UniClip.app
codesign --force --deep --sign - builds/device-test/UniClip.app
codesign --verify --deep --strict builds/device-test/UniClip.app
```

## Сборка Android APK

```sh
scripts/build-android-apk.sh
```

Результат:

```text
dist/android/UniClip-debug.apk
```

Для device-test артефакта:

```sh
mkdir -p builds/device-test
cp dist/android/UniClip-debug.apk builds/device-test/UniClip-debug.apk
```

## Установка Android APK

1. Открой настройки Android.
2. Включи Developer options.
3. Включи USB debugging.
4. Подключи телефон по USB.
5. Подтверди доверие к компьютеру на телефоне.

Проверка:

```sh
adb devices
```

Установка:

```sh
scripts/install-android-debug.sh
```

Если `adb devices` показывает `unauthorized`, разблокируй телефон и подтверди prompt.

## Запуск macOS-приложения

Обычный запуск:

```sh
open builds/device-test/UniClip.app
```

Запуск с логами:

```sh
builds/device-test/UniClip.app/Contents/MacOS/UniClip
```

Приложение появляется в верхней панели macOS. Основного Dock-окна нет.

## End-to-end тест текста

1. Запусти UniClip на Mac.
2. Открой UniClip на Android.
3. Нажми `Scan`.
4. Добавь найденный Mac.
5. Открой любое Android-приложение с текстом.
6. Выдели текст.
7. Выбери UniClip в контекстном меню.
8. На Mac вставь через `Cmd + V`.

Ожидание:

- Android показывает `✅`;
- на Mac в pasteboard находится отправленный текст;
- элемент появился в истории UniClip.

## End-to-end тест изображения

1. Запусти UniClip на Mac.
2. Убедись, что Mac добавлен в trusted list на Android.
3. В Android Gallery/Photos выбери изображение.
4. Нажми Share.
5. Выбери UniClip.
6. На Mac вставь в приложение, которое принимает изображения.

Ожидание:

- Android показывает `✅`;
- изображение доступно в macOS pasteboard;
- элемент появился в истории как `Изображение`.

Ограничение:

- Android сейчас отправляет изображение до `12 MB`;
- macOS принимает общий payload до `20 MB`.

## Локальный тест без Android

```sh
scripts/send-test-clip.swift "hello from local test"
pbpaste
```

Ожидание:

```text
hello from local test
```

## Тест истории macOS

1. Скопируй несколько разных текстов на Mac.
2. Открой UniClip через иконку menu bar или hotkey.
3. Проверь порядок: новое сверху.
4. Введи поисковый запрос.
5. Кликни элемент.
6. Проверь, что он скопирован и окно закрыто.

## Тест горячей клавиши

1. Открой UniClip.
2. Нажми `Настройки...`.
3. Нажми кнопку shortcut.
4. Введи новое сочетание.
5. Закрой окно.
6. Проверь вызов новым shortcut.

По умолчанию:

```text
Option + V
```

## Тест auto-paste

1. Дай UniClip Accessibility permission, если macOS спросит.
2. Открой текстовое поле в любом приложении.
3. Вызови UniClip history.
4. Выбери элемент.

Ожидание:

- элемент копируется в pasteboard;
- окно UniClip закрывается;
- текст вставляется в предыдущее активное приложение.

Если permission нет, UniClip должен открыть системные настройки Accessibility и показать alert.

## Проверка энергопотребления

На Mac:

- Activity Monitor -> CPU;
- Activity Monitor -> Energy;
- проверь, что UniClip не держит высокий CPU в простое;
- после сна/пробуждения проверь, что receiver все еще работает.

На Android:

- системная статистика батареи;
- проверь, что Scan остановлен, когда не нужен;
- проверь, что приложение не висит активным foreground unnecessarily.

## Частые проблемы

Mac не найден:

- оба устройства должны быть в одной сети;
- проверь firewall macOS;
- проверь, что UniClip запущен на Mac;
- нажми `Stop`, потом `Scan` на Android.

Android показывает ошибку отправки:

- Mac мог сменить IP;
- удали Mac из trusted list и добавь заново;
- проверь port `47191`;
- проверь, что macOS app не закрыт.

Клик по истории не вставляет:

- проверь Accessibility permission;
- проверь, что предыдущее приложение умеет принимать paste;
- попробуй сначала вставить вручную `Cmd + V`.

Изображение не вставляется:

- проверь размер до `12 MB`;
- попробуй PNG или JPEG;
- проверь приложение-получатель на Mac.
