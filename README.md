# Расписание ОмГТУ

Flutter-приложение расписания учебного заведения.

## Запуск

```bash
flutter pub get
flutter run
```

## iOS

В проекте не используются плагины с нативным кодом (CocoaPods только для движка Flutter). После клонирования при первой сборке iOS выполните:

```bash
flutter pub get
cd ios && pod install && cd ..
```

Далее: `flutter run` или открыть `ios/Runner.xcworkspace` в Xcode.
