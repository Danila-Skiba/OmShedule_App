# Расписание ОмГТУ — Flutter

Кроссплатформенное мобильное приложение расписания ОмГТУ

## Структура

```
lib/
├── main.dart              # Точка входа
├── app_router.dart        # Маршруты (go_router)
├── theme/
│   └── app_theme.dart     # Тема 
├── constants/
│   ├── app_colors.dart    # Цвета 
│   └── app_strings.dart   # Строки
├── models/                # Dart классы
│   ├── lesson.dart
│   ├── task.dart
│   ├── news.dart
│   ├── teacher.dart
│   ├── building.dart
│   └── chat_message.dart
├── data/
│   └── mock_data.dart     # Порт 
├── layouts/
│   └── mobile_layout.dart # Нижняя навигация
├── screens/               # Страницы Flutter
│   ├── dashboard_screen.dart
│   ├── schedule_screen.dart
│   ├── maps_screen.dart
│   ├── profile_screen.dart
│   ├── chat_screen.dart
│   └── settings_screen.dart
└── widgets/               # UI-компоненты
    ├── app_progress.dart  # Progress 
    └── app_switch.dart    # Switch 
```

## Запуск

```bash
flutter pub get
flutter run
```


