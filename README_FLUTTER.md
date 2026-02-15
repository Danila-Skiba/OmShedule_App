# Расписание ОмГТУ — Flutter

Кроссплатформенное мобильное приложение (порт с React/TypeScript).

## Структура

```
lib/
├── main.dart              # Точка входа (аналог main.tsx + App.tsx)
├── app_router.dart        # Маршруты (go_router, аналог routes.tsx)
├── theme/
│   └── app_theme.dart     # Тема (аналог theme.css + Tailwind)
├── constants/
│   ├── app_colors.dart    # Цвета (#F8FAFC, #1E3A8A и т.д.)
│   └── app_strings.dart   # Строки
├── models/                # TypeScript interfaces → Dart классы
│   ├── lesson.dart
│   ├── task.dart
│   ├── news.dart
│   ├── teacher.dart
│   ├── building.dart
│   └── chat_message.dart
├── data/
│   └── mock_data.dart     # Порт mockData.ts
├── layouts/
│   └── mobile_layout.dart # Нижняя навигация (MobileLayout.tsx)
├── screens/               # Страницы React → Flutter
│   ├── dashboard_screen.dart
│   ├── schedule_screen.dart
│   ├── maps_screen.dart
│   ├── profile_screen.dart
│   ├── chat_screen.dart
│   └── settings_screen.dart
└── widgets/               # UI-компоненты
    ├── app_progress.dart  # Progress (Radix)
    └── app_switch.dart    # Switch (Radix)
```

## Запуск

```bash
flutter pub get
flutter run
```

## Соответствие React → Flutter

| React | Flutter |
|-------|--------|
| `useState` | `StatefulWidget` + поля в `State` |
| `useEffect` | `initState` / `dispose` |
| `useNavigate` | `context.go()` / `context.push()` |
| React Router | go_router (ShellRoute = layout с детьми) |
| Radix Sheet | `showModalBottomSheet` |
| Radix Dialog | `showDialog` + `Dialog` |
| motion (Framer) | стандартные анимации / можно добавить animation пакеты |
| Tailwind цвета | `AppColors` + `ThemeData` |

Функциональность и экраны сохранены: главная, расписание, карты, профиль, помощник (чат), настройки.
