import 'package:flutter/material.dart';
import '../models/lecture_session.dart';
import '../widgets/base_container.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import 'lecture_chat_screen.dart';
import 'markdown_viewer_screen.dart';

/// Экран «Конспекты» — активные и недавние сессии.
class LectureNotesScreen extends StatefulWidget {
  const LectureNotesScreen({super.key});

  @override
  State<LectureNotesScreen> createState() => _LectureNotesScreenState();
}

class _LectureNotesScreenState extends State<LectureNotesScreen> {
  final List<LectureSession> _activeSessions = [
    LectureSession(
      id: '1',
      subject: 'Математический анализ',
      topic: 'Ряды Фурье и их применение',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      isActive: true,
      photoCount: 4,
    ),
    LectureSession(
      id: '2',
      subject: 'Физика',
      topic: 'Электромагнитная индукция',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      isActive: true,
      photoCount: 7,
    ),
  ];

  final List<LectureSession> _recentSessions = [
    LectureSession(
      id: '3',
      subject: 'Программирование',
      topic: 'Паттерны проектирования',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      isActive: false,
      photoCount: 12,
      filePath: '/notes/prog_patterns.md',
      mdContent: _mdDesignPatterns,
    ),
    LectureSession(
      id: '4',
      subject: 'Дискретная математика',
      topic: 'Теория графов',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      isActive: false,
      photoCount: 9,
      filePath: '/notes/dm_graphs.md',
      mdContent: _mdGraphTheory,
    ),
    LectureSession(
      id: '5',
      subject: 'Базы данных',
      topic: 'Нормализация, 3NF',
      dateTime: DateTime.now().subtract(const Duration(days: 4)),
      isActive: false,
      photoCount: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Конспекты')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Кнопка «Новая сессия» — под AppBar ──
                _NewSessionRow(onTap: _createNewSession),
                const SizedBox(height: 18),

                // ── Активные сессии ──
                if (_activeSessions.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.edit_note_rounded,
                    title: 'Активные',
                    count: _activeSessions.length,
                  ),
                  const SizedBox(height: 10),
                  ..._activeSessions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActiveSessionCard(
                        session: s,
                        onTap: () => _openChat(s),
                        onCompile: () => _compileSession(s),
                      ),
                    ),
                  ),
                ] else ...[
                  _buildEmptyActive(context),
                ],

                const SizedBox(height: 20),

                // ── Недавние ──
                if (_recentSessions.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Недавние',
                    count: _recentSessions.length,
                  ),
                  const SizedBox(height: 10),
                  ..._recentSessions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentSessionCard(
                        session: s,
                        onOpen: () => _openRecent(s),
                        onShare: s.mdContent != null
                            ? () => _shareRecent(s)
                            : null,
                      ),
                    ),
                  ),
                ],

                // Отступ под навбар
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    int? count,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 16, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyActive(BuildContext context) {
    final theme = Theme.of(context);
    return BaseContainer(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.note_add_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.18),
          ),
          const SizedBox(height: 10),
          Text(
            'Нет активных сессий',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Нажмите «+ Новая сессия» чтобы начать',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(LectureSession session) {
    // rootNavigator: true — открываем поверх ShellRoute (без navbar)
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LectureChatScreen(session: session),
      ),
    );
  }

  void _compileSession(LectureSession session) {
    AppDialog.show(
      context: context,
      icon: Icons.auto_awesome_rounded,
      title: 'Скомпилировать конспект?',
      message: '«${session.subject}» — ${session.photoCount} фото будут обработаны и собраны в PDF.',
      confirmText: 'Скомпилировать',
      onConfirm: () {
        AppSnackBar.show(context,
            message: 'Компиляция «${session.subject}»...',
            icon: Icons.auto_awesome_rounded);
      },
    );
  }

  void _openRecent(LectureSession session) {
    if (session.mdContent != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => MarkdownViewerScreen(
            title: session.subject,
            subtitle: session.topic,
            markdownContent: session.mdContent!,
          ),
        ),
      );
    } else {
      AppSnackBar.show(context,
          message: 'Конспект ещё не скомпилирован',
          icon: Icons.hourglass_empty_rounded);
    }
  }

  void _shareRecent(LectureSession session) {
    // TODO: реальная отправка .md файла через Share API
    AppSnackBar.show(context,
        message: 'Отправка «${session.subject}»...',
        icon: Icons.ios_share_rounded);
  }

  void _createNewSession() {
    final subjectController = TextEditingController();
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final primary = theme.colorScheme.primary;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.add_rounded, size: 20, color: primary),
              const SizedBox(width: 10),
              Text(
                'Новая сессия',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Предмет',
                  hintText: 'Математический анализ',
                  prefixIcon: Icon(Icons.book_rounded, size: 18, color: primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: topicController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Тема лекции',
                  hintText: 'Ряды Фурье',
                  prefixIcon: Icon(Icons.topic_rounded, size: 18, color: primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final subject = subjectController.text.trim();
                final topic = topicController.text.trim();
                if (subject.isEmpty) return;
                Navigator.of(ctx).pop();
                final newSession = LectureSession(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subject: subject,
                  topic: topic.isNotEmpty ? topic : 'Без темы',
                  dateTime: DateTime.now(),
                  isActive: true,
                );
                setState(() => _activeSessions.insert(0, newSession));
                _openChat(newSession);
              },
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Начать', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Кнопка «+ Новая сессия» — под AppBar, не яркая
// ═══════════════════════════════════════════════════════════════════════════════

class _NewSessionRow extends StatelessWidget {
  final VoidCallback onTap;

  const _NewSessionRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? primary.withOpacity(0.25)
                  : primary.withOpacity(0.2),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: isDark
                ? primary.withOpacity(0.06)
                : primary.withOpacity(0.04),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                'Новая сессия',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Карточка активной сессии — мягкий фон, без зелёной полоски
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveSessionCard extends StatelessWidget {
  final LectureSession session;
  final VoidCallback onTap;
  final VoidCallback onCompile;

  const _ActiveSessionCard({
    required this.session,
    required this.onTap,
    required this.onCompile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    // Мягкий тёплый фон для активных карточек
    final cardBg = isDark
        ? primary.withOpacity(0.08)
        : primary.withOpacity(0.04);
    final cardBorder = isDark
        ? primary.withOpacity(0.18)
        : primary.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: primary.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название предмета + счётчик фото
              Row(
                children: [
                  // Иконка предмета
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 18,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.subject,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.topic,
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withOpacity(0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Счётчик фото
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_rounded,
                            size: 12, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          '${session.photoCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Дата и время
              Text(
                _formatDateTime(session.dateTime),
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 14),
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_rounded,
                      label: 'Продолжить',
                      color: primary,
                      filled: true,
                      onTap: onTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Скомпилировать',
                      color: isDark
                          ? const Color(0xFFB49AFF)
                          : const Color(0xFF7C5CBF),
                      filled: false,
                      onTap: onCompile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Карточка недавней сессии
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentSessionCard extends StatelessWidget {
  final LectureSession session;
  final VoidCallback onOpen;
  final VoidCallback? onShare;

  const _RecentSessionCard({
    required this.session,
    required this.onOpen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return BaseContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.topic}  •  ${_formatDateTime(session.dateTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withOpacity(0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (session.mdContent != null && onShare != null) ...[
            Material(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onShare,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Material(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      session.mdContent != null
                          ? Icons.open_in_new_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      session.mdContent != null ? 'Открыть' : 'Нет данных',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Кнопка действия
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Форматирование даты
// ═══════════════════════════════════════════════════════════════════════════════

const _monthNamesShort = [
  'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];

String _formatDateTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final time =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  if (date == today) return 'Сегодня, $time';
  if (date == today.subtract(const Duration(days: 1))) return 'Вчера, $time';
  return '${dt.day} ${_monthNamesShort[dt.month - 1]}, $time';
}

// ═══════════════════════════════════════════════════════════════════════════════
// Тестовые MD-конспекты
// ═══════════════════════════════════════════════════════════════════════════════

const _mdDesignPatterns = '''
# Паттерны проектирования

## Введение

Паттерны проектирования — это типовые решения часто встречающихся проблем при разработке программного обеспечения. Они представляют собой **проверенные временем** подходы к организации кода.

> «Каждый паттерн описывает проблему, которая снова и снова возникает в нашей среде, а затем суть решения этой проблемы» — Кристофер Александер

---

## 1. Порождающие паттерны

### Singleton (Одиночка)

Гарантирует, что у класса есть **только один экземпляр**, и предоставляет глобальную точку доступа к нему.

```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Future<void> query(String sql) async {
    // выполнение запроса
  }
}
```

**Когда использовать:**
- Логгер приложения
- Менеджер конфигурации
- Пул подключений к БД

### Factory Method (Фабричный метод)

Определяет общий интерфейс для создания объектов, позволяя подклассам изменять тип создаваемого объекта.

```dart
abstract class Transport {
  void deliver();
}

class Truck implements Transport {
  @override
  void deliver() => print('Доставка по земле');
}

class Ship implements Transport {
  @override
  void deliver() => print('Доставка по морю');
}
```

---

## 2. Структурные паттерны

### Adapter (Адаптер)

Позволяет объектам с **несовместимыми интерфейсами** работать вместе. Оборачивает один объект так, чтобы он выглядел как другой.

| Паттерн | Назначение | Пример |
|---------|-----------|--------|
| Adapter | Совместимость интерфейсов | XML → JSON конвертер |
| Decorator | Добавление поведения | Логирование запросов |
| Facade | Упрощение интерфейса | API-клиент |

### Observer (Наблюдатель)

Определяет механизм подписки, позволяющий объектам следить за событиями другого объекта.

```dart
class EventBus {
  final _listeners = <String, List<Function>>{};

  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void emit(String event, [dynamic data]) {
    _listeners[event]?.forEach((fn) => fn(data));
  }
}
```

---

## 3. Поведенческие паттерны

### Strategy (Стратегия)

Определяет семейство алгоритмов, инкапсулирует каждый из них и делает их **взаимозаменяемыми**.

Пример: разные стратегии сортировки расписания:
- По времени начала
- По предмету (алфавит)
- По приоритету

### State (Состояние)

Позволяет объекту менять поведение при изменении внутреннего состояния. Используется в Flutter через `ChangeNotifier` и `Provider`.

---

## Итоги лекции

1. Паттерны — не готовый код, а **описание подхода** к решению задачи
2. Не нужно применять паттерны ради паттернов — *используйте когда есть реальная проблема*
3. В Flutter активно используются: **Observer**, **Strategy**, **Singleton**, **Builder**
4. Паттерны помогают писать код, который легче поддерживать и расширять
''';

const _mdGraphTheory = '''
# Теория графов

## Основные определения

**Граф** — это пара G = (V, E), где:
- **V** — конечное множество *вершин* (vertices)
- **E** — множество *рёбер* (edges), соединяющих вершины

> Теория графов зародилась в 1736 году, когда Леонард Эйлер решил задачу о Кёнигсбергских мостах.

---

## Виды графов

### По направленности рёбер

| Тип | Описание | Пример |
|-----|----------|--------|
| Неориентированный | Рёбра без направления | Дорожная сеть |
| Ориентированный (орграф) | Рёбра имеют направление | Подписки в соцсети |
| Смешанный | Часть рёбер ориентирована | Карта улиц |

### По наличию циклов

- **Дерево** — связный граф без циклов
- **Лес** — несвязный граф без циклов (набор деревьев)
- **DAG** — ориентированный ациклический граф (например, git-история)

---

## Способы представления

### 1. Матрица смежности

Квадратная матрица размером `|V| × |V|`, где `a[i][j] = 1`, если есть ребро из i в j.

```
    A  B  C  D
A [ 0, 1, 1, 0 ]
B [ 1, 0, 0, 1 ]
C [ 1, 0, 0, 1 ]
D [ 0, 1, 1, 0 ]
```

**Плюсы:** быстрая проверка наличия ребра — `O(1)`
**Минусы:** расход памяти `O(V²)` — плохо для разреженных графов

### 2. Список смежности

Для каждой вершины хранится список соседей:

```dart
final graph = <String, List<String>>{
  'A': ['B', 'C'],
  'B': ['A', 'D'],
  'C': ['A', 'D'],
  'D': ['B', 'C'],
};
```

**Плюсы:** экономия памяти `O(V + E)`
**Минусы:** проверка ребра за `O(deg(v))`

---

## Обход графов

### BFS — поиск в ширину

Обходит граф **послойно** — сначала все соседи, потом соседи соседей.

```dart
List<String> bfs(Map<String, List<String>> graph, String start) {
  final visited = <String>{};
  final queue = Queue<String>()..add(start);
  final result = <String>[];

  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    if (visited.contains(node)) continue;
    visited.add(node);
    result.add(node);
    queue.addAll(graph[node] ?? []);
  }
  return result;
}
```

**Применение:** кратчайший путь в невзвешенном графе, поиск компонент связности.

### DFS — поиск в глубину

Идёт **вглубь** до тупика, затем откатывается назад.

**Применение:** топологическая сортировка, поиск циклов, поиск мостов.

---

## Кратчайшие пути

### Алгоритм Дейкстры

Находит кратчайший путь от одной вершины до всех остальных во **взвешенном графе без отрицательных рёбер**.

Сложность: `O((V + E) · log V)` с приоритетной очередью.

### Алгоритм Флойда-Уоршелла

Находит кратчайшие расстояния между **всеми парами** вершин. Сложность: `O(V³)`.

---

## Итоги

1. Граф — универсальная структура для моделирования **связей между объектами**
2. Выбор представления зависит от плотности графа и типа операций
3. BFS — для кратчайших путей, DFS — для структурного анализа
4. Алгоритм Дейкстры — *основной инструмент* для взвешенных графов
5. Теория графов применяется в навигации, соцсетях, компиляторах, расписаниях
''';
