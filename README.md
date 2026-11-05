# TimerApp

Простой таймер обратного отсчёта на SwiftUI (iOS 16+), без зависимостей.

## Структура

```
TimerApp/
├── TimerApp.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/TimerApp.xcscheme
├── TimerApp/
│   ├── TimerAppApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets/ (AppIcon: светлая, тёмная и tinted иконки в стиле iOS 18)
├── build_ipa.sh
└── README.md
```

## Сборка

```
xcodebuild -scheme TimerApp -configuration Release
```

Release-конфигурация собирается без подписи (CODE_SIGNING_ALLOWED = NO),
поэтому команда проходит без аккаунта разработчика.

## Подпись через свой Apple ID

### Вариант А. Прямо в Xcode
1. Откройте TimerApp.xcodeproj → target TimerApp → Signing & Capabilities.
2. Выберите Team (Personal Team = ваш Apple ID) и поменяйте Bundle Identifier
   на уникальный, например `com.ваш-ник.timerapp`.
3. Выберите свой iPhone и нажмите Run (используется конфигурация Debug с автоподписью).

### Вариант Б. Через Sideloadly / AltStore / iOS App Signer
1. Выполните `./build_ipa.sh` — получите неподписанный `TimerApp.ipa`.
2. Перетащите его в Sideloadly (или AltStore), введите Apple ID — программа сама
   подпишет и установит приложение.
3. Бесплатный аккаунт: подпись действует 7 дней, потом нужно переподписать.

Если хотите подписывать Release прямо в Xcode (Archive), удалите две строки
`CODE_SIGNING_ALLOWED = NO;` и `CODE_SIGNING_REQUIRED = NO;` в Release-конфигурации
target в project.pbxproj и укажите Team.
