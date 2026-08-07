# Фаза 0. Инвентаризация виджетов (код не менялся)

Базовая точка зафиксирована 2026-08-07, ветка `liquid_glass_design`.

## Предусловия

| # | Требование | Статус | Факт |
|---|---|---|---|
| 1 | Xcode 26+, `xcode-select -p` на него | ✅ | Xcode 26.2 (17C52), `/Applications/Xcode.app/Contents/Developer` |
| 2 | Симуляторы iOS 26 **и** iOS 18 | ✅ | runtimes iOS 26.2 (23C54) и iOS 18.6 (22G86) |
| 3 | Устройство/эмулятор Android | ❌ | нет Android SDK (`adb`/`emulator`/`sdkmanager` не найдены), **в проекте отсутствует каталог `android/`** |
| 4 | Чистая ветка `feature/adaptive-platform-ui` | ❌ | текущая ветка `liquid_glass_design`, не создана |
| 5 | Приложение собирается до начала работ | ⚠️ частично | iOS simulator debug — ✅ `Built build/ios/iphonesimulator/Runner.app` (30,3 s); Android — проверить негде |

Базовая точка качества:

- `flutter analyze` — **95 issues**, все уровня `info` (в основном `deprecated_member_use: withOpacity`). Ошибок и warning нет.
- `flutter test` — **9 passed, 1 failed**. Падает `test/widget_test.dart` («Counter increments smoke test») — заготовка от `flutter create`, к приложению отношения не имеет. Проходят `schedule_data_test.dart` и `select_screen_test.dart`.

## Окружение

- Flutter 3.44.8 stable, Dart 3.12.2
- `pubspec.yaml`: `environment.sdk: '>=3.2.0 <4.0.0'`; у `adaptive_platform_ui 0.1.111` требование `sdk: ^3.9.2` — текущий SDK его удовлетворяет, но нижнюю границу проекта придётся поднять до `>=3.9.2`
- Платформенные каталоги в репозитории: `ios/`, `macos/`. Каталогов `android/`, `web/` нет.

## Таблица инвентаризации

Счётчик — число вхождений идентификатора в `lib/`, включая объявления собственных обёрток.

| Текущий виджет | Кол-во | Файлы | Заменяем? | Комментарий |
|---|---|---|---|---|
| `Scaffold` | 8 | dashboard, schedule, tasks, settings, select, add_task, calendar_picker, mobile_layout | Да | → `AdaptiveScaffold`, Фаза 2 |
| `AppBar` | 6 | platform_utils, schedule, glass_app_bar | Да | → `AdaptiveAppBar` с `useNativeToolbar: true` |
| `CupertinoNavigationBar` | 2 | platform_utils | Да | поглощается `AdaptiveAppBar` |
| кастомный `BottomAppBar` + `BackdropFilter` | 1 | mobile_layout | Да | → `AdaptiveBottomNavigationBar(useNativeBottomBar: true)`; сейчас стекло нарисовано вручную |
| `ElevatedButton` | 9 | dashboard, schedule, add_task, calendar_picker, add_task_dialog | Да | → `AdaptiveButton(style: .filled)` |
| `FilledButton` | 1 | schedule | Да | → `AdaptiveButton(style: .tinted)` |
| `OutlinedButton` | 2 | add_task_dialog | Да | → `AdaptiveButton(style: .bordered)` |
| `TextButton` | 4 | dashboard, schedule, calendar_picker | Да | → `AdaptiveButton(style: .plain)` |
| `CupertinoButton` | 5 | dashboard, schedule, add_task, calendar_picker, add_task_dialog | Да | → `AdaptiveButton` |
| `IconButton` | 10 | select, schedule, dashboard, calendar_picker, add_task, maps, tasks | Да | → `AdaptiveButton.icon`; нужны SF Symbols |
| `Switch` / `CupertinoSwitch` | 2+2 | app_switch | Да | обёртка `AppSwitch` → `AdaptiveSwitch` внутри; **единственное место использования — settings_screen.dart:541** |
| `TextField` | 7 | select, add_task, app_dialog, add_task_dialog | Да | → `AdaptiveTextField`; **`hintText` → `placeholder`** |
| `CupertinoTextField` | 2 | add_task | Да | то же |
| `CupertinoPicker` | 1 | add_task | Возможно | кандидат на `AdaptiveTimePicker.show` — проверить сценарий |
| `ListTile` | 1 | settings (`_SettingsTile`) | Да | → `AdaptiveListTile` |
| `showDialog` + `Dialog` | 2 | dashboard, app_dialog | Да | обёртка `AppDialog.show` → `AdaptiveAlertDialog.show` |
| `CupertinoAlertDialog` | 2 | app_dialog | Да | то же |
| `showSnackBar` / `SnackBar` | 1+2 | app_snackbar | Да | обёртка `AppSnackBar` → `AdaptiveSnackBar.show`; **на iOS баннер сверху — визуальное изменение** |
| `showModalBottomSheet` | 4 | dashboard, schedule | Нет | прямого аналога в каталоге пакета нет → оставляем |
| `showCupertinoModalPopup` | 3 | dashboard, schedule | Нет | то же |
| `InkWell` | 16 | select, maps, dashboard, schedule, settings, personal_task_card, app_dialog | Нет | нет аналога; большинство — внутри ячеек списков (см. стоп-правило 1) |
| `GestureDetector` | 14 | main, dashboard, settings, schedule, mobile_layout, personal_task_card | Нет | нет аналога |
| `BackdropFilter` (ручное стекло) | 9 | dashboard, schedule, mobile_layout, glass_app_bar, base_container | Частично | там, где стекло даст нативный `AdaptiveAppBar`/`AdaptiveBottomNavigationBar`, ручной блюр убираем |
| `FloatingActionButton`, `Slider`, `Checkbox`, `Radio`, `SegmentedButton`, `Card`, `ExpansionTile`, `Badge`, `Tooltip`, `TabBar`, `PopupMenuButton`, `showDatePicker`, `showTimePicker` | 0 | — | — | в проекте не используются |

## Места внутри лениво строящихся списков (критично для стоп-правила 1)

| Файл:строка | Конструкция | Что внутри | Риск |
|---|---|---|---|
| `select_screen.dart:169` | `ListView.builder` (сотни групп/преподавателей) | `Material` + `InkWell` + `Container` | **Высокий.** Нативные виджеты сюда не ставить ни при каких условиях |
| `maps_screen.dart:106` | `GridView.builder` | карточки корпусов | Высокий |
| `dashboard_screen.dart:1399` | `PageView.builder` | страницы дней | Высокий |
| `schedule_screen.dart:441`, `:1459` | `PageView.builder` | недели/дни расписания | Высокий |
| `schedule_screen.dart:706` | `ListView.separated` | карточки пар | Высокий |
| `dashboard_screen.dart:475`, `:829`, `:863` | `ListView.separated` | новости, задачи | Высокий |
| `dashboard_screen.dart:70`, `maps_screen.dart:25`, `tasks_screen.dart:126` | `SliverList` | секции экранов | Средний |
| `settings_screen.dart:48` | `SliverList` + `SliverChildListDelegate` | фиксированный список секций, внутри — `AppSwitch` (1 шт.) | Низкий: делегат не ленивый, элементов мало, 1 нативный компонент укладывается в бюджет 3–5 |

Вывод: **все длинные списки приложения ленивые**. Замену `AdaptiveButton`/`AdaptiveSwitch` внутри ячеек не делаем нигде; нативные компоненты допустимы только в «шапке» экранов, диалогах и на экране настроек.

## Открытые вопросы до Фазы 1

1. **Android недоступен.** Каталога `android/` в проекте нет, SDK не установлен. Пункты Фазы 4 по Android и стоп-правило 4 («скриншоты Android совпадают с базовой точкой») выполнить нельзя.
2. **macOS.** В репозитории есть `macos/`, но `adaptive_platform_ui` поддерживает только iOS и Android. Добавление зависимости может сломать сборку под macOS — нужно решить, поддерживается ли эта цель.
3. **Ветка.** Требуемая `feature/adaptive-platform-ui` не создана; работа идёт в `liquid_glass_design`.
