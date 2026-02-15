# Расписание ОмГТУ

Flutter-приложение расписания учебного заведения.

## Запуск

```bash
flutter pub get
flutter run
```

## iOS: CocoaPods

Для сборки под iOS нужен CocoaPods (используется плагинами вроде `shared_preferences`).

### Установка CocoaPods (если ещё не установлен)

**Через Homebrew (рекомендуется на macOS):**
```bash
brew install cocoapods
```

**Или через Ruby gem:**
```bash
sudo gem install cocoapods
```

### Установка подов проекта

После установки CocoaPods выполните из корня проекта:

```bash
flutter pub get
cd ios && pod install && cd ..
```

Дальше можно собирать и запускать iOS-приложение: `flutter run` или открыть `ios/Runner.xcworkspace` в Xcode.
