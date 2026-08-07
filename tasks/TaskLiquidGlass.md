# Промпт: полная миграция виджетов приложения на `adaptive_platform_ui`

> Как пользоваться: заполни блок «Контекст проекта», отдай файл целиком AI-агенту в корне репозитория. Разделы «Стоп-правила» и «Критерии приёмки» не удаляй.

---

## Роль и цель

Ты — senior Flutter-разработчик. Задача: заменить максимально возможное количество виджетов существующего приложения на аналоги из пакета `adaptive_platform_ui`, чтобы на iOS 26+ приложение получило нативный Liquid Glass, на iOS 18 и ниже — обычный Cupertino, а на Android — Material 3.

Работай **строго по фазам**, каждую фазу заканчивай сборкой под обе платформы и отдельным коммитом. Не переходи к следующей фазе без подтверждения.

---

## Контекст проекта

- **Приложение:** {{ описание, ключевые экраны }}
- **Flutter / Dart:** {{ вывод `flutter --version` }}
- **Текущая база UI:** {{ Material / Cupertino / микс }}
- **Минимальная iOS:** {{ например 13.0 }} — **не менять**
- **Целевые платформы:** {{ iOS + Android }} (пакет поддерживает только их; web/desktop не поддерживаются)
- **Навигация:** {{ Navigator / go_router / auto_route }}
- **Стейт:** {{ Riverpod / Bloc / Provider }}
- **Локали:** {{ ru, en, ... }}
- **Экраны с длинными списками:** {{ перечисли — там будут особые правила }}

---

## Предусловия (проверь и отчитайся)

1. Xcode 26+, `xcode-select -p` указывает на него.
2. Симулятор/устройство с iOS 26 **и** с iOS 18 — нужны оба для проверки фолбэков.
3. Устройство/эмулятор Android.
4. Чистая ветка `feature/adaptive-platform-ui`, отдельная от основной разработки.
5. Приложение собирается и запускается **до** начала работ на всех трёх конфигурациях. Зафиксируй это как базовую точку.

Если чего-то нет — остановись и скажи.

---

## Фаза 0. Инвентаризация (код не меняем)

Пройди по `lib/` и составь таблицу-отчёт: какие виджеты используются, сколько раз, в каких файлах. Формат:

| Текущий виджет | Кол-во | Файлы | Заменяем? | Комментарий |
|---|---|---|---|---|

Отдельно пометь **все места, где виджет находится внутри `ListView.builder`, `GridView`, `SliverList` или другого лениво строящегося списка** — это критично для следующих фаз.

Покажи таблицу и жди подтверждения.

---

## Фаза 1. Подключение и слой абстракции

1. Добавь зависимость с **точной** версией, без каретки:

```yaml
dependencies:
  adaptive_platform_ui: 0.1.111   # проверь актуальную на pub.dev и зафиксируй
```

Причина: пакет в версии 0.1.x, API нестабилен, ломающие изменения прилетают в патч-релизах.

2. Создай слой обёрток `lib/ui/adaptive/`. Каждый файл — тонкая обёртка над виджетом пакета:

```
lib/ui/adaptive/
  app_button.dart
  app_scaffold.dart
  app_text_field.dart
  app_list_tile.dart
  ...
  adaptive_exports.dart   // единый барель-файл
```

Экраны импортируют **только** `package:{{ app }}/ui/adaptive/adaptive_exports.dart`, никогда не сам пакет напрямую. Это единственная страховка на случай, когда выйдет официальный `cupertino_ui` или когда пакет сломает API.

3. Прогони сборку. Визуально ничего не изменилось — это ожидаемо.

---

## Фаза 2. Каркас приложения

**`MaterialApp` / `CupertinoApp` → `AdaptiveApp`**

```dart
AdaptiveApp(                       // или AdaptiveApp.router(routerConfig: router)
  title: '{{ название }}',
  themeMode: ThemeMode.system,
  materialLightTheme: {{ текущая светлая тема }},
  materialDarkTheme: {{ текущая тёмная тема }},
  cupertinoLightTheme: const CupertinoThemeData(brightness: Brightness.light),
  cupertinoDarkTheme: const CupertinoThemeData(brightness: Brightness.dark),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,   // обязательно
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [Locale('ru'), Locale('en')],
  home: const HomePage(),
)
```

⚠️ **`GlobalCupertinoLocalizations.delegate` пропустить нельзя** — без него date/time-пикеры и системные кнопки останутся на английском независимо от языка системы.

Отдельно перенеси текущую Material-тему в `materialLightTheme`/`materialDarkTheme` **без изменений**, чтобы Android остался пиксель-в-пиксель прежним.

**`Scaffold` → `AdaptiveScaffold`**, `AppBar` → `AdaptiveAppBar`, нижняя навигация → `AdaptiveBottomNavigationBar`:

```dart
AdaptiveScaffold(
  appBar: AdaptiveAppBar(
    title: 'Расписание',
    useNativeToolbar: true,          // нативный UIToolbar с Liquid Glass
    actions: [
      AdaptiveAppBarAction(
        onPressed: () {},
        iosSymbol: 'gear',           // SF Symbol
        icon: Icons.settings,        // фолбэк
      ),
    ],
  ),
  bottomNavigationBar: AdaptiveBottomNavigationBar(
    useNativeBottomBar: true,        // нативный UITabBar, включён по умолчанию
    items: const [
      AdaptiveNavigationDestination(icon: 'calendar', label: 'Расписание'),
      AdaptiveNavigationDestination(icon: 'newspaper', label: 'Новости'),
    ],
    selectedIndex: index,
    onTap: (i) => setState(() => index = i),
  ),
  body: content,
)
```

После этой фазы — обязательная проверка на iOS 26, iOS 18 и Android. Именно тут ломается больше всего.

---

## Фаза 3. Замена виджетов по каталогу

Таблица соответствий. Заменяй сверху вниз, коммит на каждую группу.

### Кнопки и управление

| Было | Стало | Примечание |
|---|---|---|
| `ElevatedButton` | `AdaptiveButton(style: AdaptiveButtonStyle.filled)` | основное действие |
| `FilledButton.tonal` | `AdaptiveButton(style: .tinted)` | |
| `OutlinedButton` | `AdaptiveButton(style: .bordered)` | |
| `TextButton` | `AdaptiveButton(style: .plain)` | |
| `CupertinoButton` | `AdaptiveButton` | |
| `IconButton` | `AdaptiveButton.icon(icon: ...)` | |
| кнопка с кастомным содержимым | `AdaptiveButton.child(child: ...)` | |
| `FloatingActionButton` | `AdaptiveFloatingActionButton` | `mini: true` для маленького |
| `Switch` / `CupertinoSwitch` | `AdaptiveSwitch` | |
| `Slider` | `AdaptiveSlider` | |
| `Checkbox` | `AdaptiveCheckbox` | поддерживает `tristate` |
| `Radio<T>` | `AdaptiveRadio<T>` | |
| `SegmentedButton` / `CupertinoSegmentedControl` | `AdaptiveSegmentedControl` | принимает `sfSymbols: [...]` |

Размеры кнопок: `AdaptiveButtonSize.small` (28pt), `.medium` (36pt, дефолт), `.large` (44pt). Сопоставь с текущими размерами, не оставляй дефолт везде подряд.

### Ввод

| Было | Стало |
|---|---|
| `TextField` / `CupertinoTextField` | `AdaptiveTextField` |
| `TextFormField` | `AdaptiveTextFormField` (валидатор и `onSaved` работают как прежде) |
| группа полей в настройках | `AdaptiveFormSection` / `AdaptiveFormSection.insetGrouped` |

Внимание: у `AdaptiveTextField` параметр называется `placeholder`, а не `labelText`/`hintText`. Проверь каждое поле — молча потерянные подписи это частая ошибка при такой миграции.

### Списки и контейнеры

| Было | Стало |
|---|---|
| `ListTile` | `AdaptiveListTile` (`hideBottomDivider: true` для последнего элемента) |
| `Card` | `AdaptiveCard` |
| `ExpansionTile` | `AdaptiveExpansionTile` |
| `Badge` | `AdaptiveBadge` |
| `Tooltip` | `AdaptiveTooltip` |
| `TabBar` + `TabBarView` | `AdaptiveTabBarView(tabs: [...], children: [...])` |

### Диалоги и оверлеи

| Было | Стало |
|---|---|
| `showDialog` + `AlertDialog` | `AdaptiveAlertDialog.show(context: ..., actions: [AlertAction(...)])` |
| диалог с полем ввода | `AdaptiveAlertDialog.show(input: AdaptiveAlertDialogInput(...))` — возвращает введённый текст |
| `ScaffoldMessenger.showSnackBar` | `AdaptiveSnackBar.show(context, message: ..., type: AdaptiveSnackBarType.success)` |
| `PopupMenuButton` | `AdaptivePopupMenuButton.text/.icon/.widget` |
| меню по长 нажатию | `AdaptiveContextMenu(actions: [...])` |
| `showDatePicker` | `AdaptiveDatePicker.show(...)` |
| `showTimePicker` | `AdaptiveTimePicker.show(...)` |

`AdaptiveSnackBar` на iOS показывается баннером **сверху**, на Android — снизу. Если в приложении есть логика, завязанная на позицию или на `SnackBarAction`, проверь её отдельно.

### Иконки

На iOS 26 виджеты ждут строку SF Symbol, на остальных платформах — `IconData`. Используй хелпер пакета:

```dart
icon: PlatformInfo.isIOS26OrHigher() ? 'trash' : Icons.delete
```

Составь единый словарь соответствий `IconData` ↔ SF Symbol в одном файле `lib/ui/adaptive/app_icons.dart`, не размазывай тернарники по экранам.

---

## Стоп-правила

Это ограничения, нарушение которых ломает приложение. Не обходи их «потому что так красивее».

1. **Не ставь нативные виджеты внутрь лениво строящихся списков.** На iOS 26 `AdaptiveButton`, `AdaptiveSwitch`, `AdaptiveSlider`, `AdaptiveSegmentedControl` — это `UiKitView`, то есть отдельный нативный слой в композиторе. В `ListView.builder` с десятками ячеек это гарантированная просадка скролла. В ячейках списков оставляй обычные Flutter-виджеты. Ориентир: не более 3–5 нативных компонентов на экране одновременно.

2. **`IOS26NativeSearchTabBar` не использовать вообще.** Автор пакета сам пишет, что фича подменяет root view controller Flutter нативным `UITabBarController`, из-за чего ломаются `initState`/`dispose`, становится ненадёжным `Navigator.pop()`, Provider/Riverpod/Bloc теряют состояние, hot reload не работает и возможны утечки памяти. Прямая рекомендация автора: только прототипы и демо, не продакшн.

3. **Не менять минимальную версию iOS вверх.**

4. **Не трогать Android-ветку визуально.** После миграции скриншоты Android-версии должны совпадать с базовой точкой.

5. **Не заменять виджеты, у которых нет прямого аналога**, придумывая обходные пути. Если аналога нет — оставь как есть и внеси в отчёт.

6. **Не импортировать `adaptive_platform_ui` напрямую в экранах** — только через `lib/ui/adaptive/`.

7. При ошибке сборки не подменяй молча API на другой — останавливайся и докладывай.

---

## Фаза 4. Проверка

Прогони на трёх конфигурациях, по каждому пункту дай статус:

**iOS 26 (release-сборка на устройстве):**
- [ ] Toolbar и tab bar показывают стекло, контент под ними просвечивает и искажается при скролле
- [ ] Скролл главного списка держит целевой fps, raster thread без выпадающих кадров
- [ ] Модалки и шиты открываются поверх стеклянных элементов, тени не протекают
- [ ] SF Symbols отрисовались, нет пустых квадратов
- [ ] Тёмная тема корректна
- [ ] При включённом Reduce Transparency интерфейс читаем

**iOS 18:**
- [ ] Обычные Cupertino-виджеты, никаких пустых прямоугольников на месте platform views
- [ ] Все экраны открываются, пикеры на русском языке

**Android:**
- [ ] Визуально идентично базовой точке
- [ ] Все диалоги, снекбары и пикеры работают

**Общее:**
- [ ] `flutter analyze` без новых warning
- [ ] Существующие тесты проходят (виджет-тесты, скорее всего, придётся править — перечисли какие)

---

## Формат отчёта

1. Таблица инвентаризации из Фазы 0 с проставленным финальным статусом по каждой строке.
2. Список заменённых виджетов: было → стало, количество мест.
3. Список **не заменённых** и почему.
4. Места, где пришлось оставить платформенный тернарник, и почему.
5. Что нужно проверить руками на устройстве.
6. Риски: какие части приложения наиболее вероятно сломаются при обновлении пакета.
