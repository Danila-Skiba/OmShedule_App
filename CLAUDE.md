# CLAUDE.md

Указания для Claude Code при работе с этим репозиторием.

## Обзор проекта

**omstu_schedule** — кроссплатформенное мобильное приложение «Расписание ОмГТУ»
на Flutter/Dart (порт с предыдущей версии на React/TypeScript — многие файлы содержат
комментарии вида «аналог routes.tsx»). Основной язык кода, комментариев и UI — русский.

Цель: показывать расписание занятий (по группе / преподавателю / аудитории),
вести личные задачи, конспекты лекций с распознаванием и компиляцией через бэкенд,
новости, карту корпусов и чат-помощника.

Целевые платформы: iOS (основная, ветка `version_for_ios`), Android, macOS.
Приложение залочено в портретную ориентацию, локали `ru` (основная) и `en`.

## Команды

```bash
flutter pub get          # установка зависимостей
flutter run              # запуск на подключённом устройстве/симуляторе
flutter analyze          # статический анализ (flutter_lints + правила ниже)
flutter test             # запуск тестов (сейчас только test/widget_test.dart)
flutter build ios        # сборка под iOS
```

Правила линтера (`analysis_options.yaml`): `avoid_print`, `prefer_const_constructors`,
`prefer_const_declarations`, `use_key_in_widget_constructors`. Для логов используйте
`debugPrint`, а не `print`.

## Источники данных

- **Расписание** берётся напрямую из открытого API ОмГТУ (`ApiClient` в
  `lib/core/services/schedule_repository.dart`):
  `https://rasp.omgtu.ru/api/schedule/{group|person|auditorium}/{id}?start=YYYY.MM.DD&finish=YYYY.MM.DD`.
  Соответствие «название → id» — в JSON-ассетах `assets/data/`
  (`groups.json`, `persons.json`, `auditories.json`; поля `id`/`name`/`desc`).
  Их читает `ScheduleData.load()` (`lib/data/schedule_data.dart`) один раз в
  `main()` до `runApp`; дальше доступ синхронный: списки
  `ScheduleData.groups/persons/auditoriums` (записи `ScheduleEntry` с описанием)
  и карты `ScheduleData.getgroups/getpersons/getauditorium` («название → id»).
  Обновление справочников — выгрузка из API вуза ноутбуком
  `dags/data/schedule/update_data.ipynb` соседнего репозитория `OmShedule-News`,
  JSON-файлы копируются в `assets/data/`. Своего бэкенда для расписания нет.
- **Новости** (главная страница) парсятся прямо с сайта вуза
  `https://www.omgtu.ru/news/` (`NewsRepositoryImpl` в `schedule_news.dart`):
  HTML в кодировке windows-1251 (декод через `enough_convert`), разбор через
  пакет `html` (`div.news-card`). Картинки — по прямым HTTPS-URL
  (`cached_network_image`). Бэкенда у приложения больше нет.
- **Кеш новостей** — `NewsService` (`news_service.dart`): суточный TTL,
  «обновление при запуске» (cron на iOS невозможен), офлайн-фолбэк на
  устаревший кеш. Кеш хранится в `news_cache.json` (documents dir).

## Архитектура

Слоистая структура. Каталог `lib/core/` — инфраструктура, `lib/` верхнего уровня — UI.

```
lib/
├── main.dart              # Точка входа: init сервисов, MultiProvider, MaterialApp.router
├── app_router.dart        # go_router: ShellRoute с MobileLayout + вложенные экраны
├── core/
│   ├── services/                  # Работа с сетью, хранилищем, бизнес-логика
│   │   ├── schedule_repository.dart   # ApiClient: расписание напрямую из API ОмГТУ
│   │   ├── schedule_cache_service.dart# In-memory кеш расписания, TTL 30 мин, префетч недель
│   │   ├── task_service.dart          # Личные задачи → локальный JSON-файл
│   │   ├── schedule_news.dart         # NewsRepository: парсинг новостей с сайта вуза
│   │   ├── news_service.dart          # Кеш новостей (24ч, обновление при запуске)
│   │   └── settings_service.dart      # Обёртка над SharedPreferences (тема, фильтры)
│   ├── state/                     # ChangeNotifier-контроллеры
│   │   ├── schedule_week_controller.dart  # Выбранная дата/неделя, загрузка, состояние
│   │   └── filter_controller.dart         # Тип фильтра (group/teacher/audience/personal)
│   ├── theme/                     # ThemeNotifier + AppTheme (light/dark, акцентный цвет)
│   └── utils/
│       ├── week_service.dart          # Расчёт недель (Пн–Вс), форматирование дат
│       └── platform_utils.dart        # iOS vs Android виджеты (лоадеры, переходы)
├── models/                # Доменные модели с fromJson/toJson (Lesson, PersonalTask,
│                          #   LectureSession, News, Building, WeekPeriod, ChatMessage…)
├── data/                  # Справочники: группы/преподаватели/аудитории, корпуса, mock
├── layouts/mobile_layout.dart  # Нижняя навигация: Главная / Расписание / Задачи
├── screens/               # Экраны (по одному на маршрут)
├── widgets/               # Переиспользуемые UI-компоненты (glass_app_bar, app_dialog,
│                          #   app_switch, math_markdown, personal_task_card…)
└── constants/             # app_colors, app_strings, app_constants
```

### Управление состоянием

Подход — **`provider` + `ChangeNotifier`** (Riverpod не используется):

- Глобально в `main.dart` через `MultiProvider`: `ThemeNotifier`.
- Сервисы-синглтоны: `TaskService.instance`,
  `ScheduleCacheService.instance` (приватный конструктор + статический геттер).
- Локальное состояние экранов: `ChangeNotifier`-контроллеры (`ScheduleWeekController`,
  `FilterController`) и `ValueNotifier`.

При добавлении состояния следуйте этому паттерну (provider/ChangeNotifier/singleton).

### Навигация

`go_router` (`app_router.dart`). Вкладки обёрнуты в `ShellRoute` с `MobileLayout`
(нижняя навигация: Главная `/`, Расписание `/schedule`, Задачи `/tasks`; плюс `/maps`).
Экран `/settings` — вне шелла. Переходы между вкладками — fade 150мс.
Параметры между экранами передаются через `state.extra` (Map).

## Ключевые доменные понятия

- **Расписание** грузится по периоду недели (`WeekPeriod`) и фильтру: id группы,
  ФИО преподавателя или id аудитории. Маппинг «название → id» — в `ScheduleData`
  (`getgroups`/`getpersons`/`getauditorium`). Кеш по ключу «фильтр + начало недели»
  (TTL 30 мин, `ScheduleCacheService`).
- **Неделя** — Пн(1)…Вс(7), даты нормализованы без времени (`WeekService`).
- **Личные задачи** (`PersonalTask`) — хранятся локально в JSON
  (`personal_tasks.json` в documents dir), привязаны к дате/времени. Вкладка «Задачи»
  (`tasks_screen.dart`) показывает задачи на сегодня/завтра.

## Конвенции

- **Язык**: комментарии, строки UI, doc-комментарии `///` — на русском. Продолжайте так же.
- **Модели**: у каждой доменной модели — фабрика `fromJson` и, где нужно, `toJson`/`copyWith`.
  Nullable-поля для необязательных данных.
- **Сеть**: `package:http`; ответы декодируются как `utf-8`; сервисы возвращают
  result-объекты (напр. `ScheduleLoadResult`, `NewsLoadResult`) с полями `data` + `error`
  вместо выброса исключений наружу.
- **Платформозависимость**: используйте хелперы из `platform_utils.dart`
  (`buildLoader`, `buildRoute`, `isIOS`) для iOS/Android-специфичного поведения.
- **Тема/стиль**: iOS-стилистика «Liquid Glass» (`BackdropFilter`, полупрозрачные
  градиенты). Цвета — через `AppTheme`/`app_colors`, а не хардкод.
- **Настройки**: любые персистентные простые значения — через `SettingsService`
  (обёртка над `SharedPreferences`), ключи — в `PrefsKeys`.

## Замечания

- Справочники в `assets/data/` — снимок API вуза: названия групп/аудиторий со
  временем исчезают. Сохранённые в `SharedPreferences` фильтры перед
  использованием проверяйте через `ScheduleData.hasGroup/hasPerson/hasAuditorium`.
- `test/widget_test.dart` — незаполненный шаблон (тело закомментировано);
  из реальных тестов есть только `test/schedule_data_test.dart` (загрузка
  справочников), при доработках стоит добавлять.
