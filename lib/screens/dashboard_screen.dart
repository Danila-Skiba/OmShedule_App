import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/core/services/schedule_news.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../data/building_data.dart';
import '../constants/app_constants.dart';
import '../widgets/base_container.dart';
import '../models/lesson.dart';
import '../models/news.dart';
import '../models/personal_task.dart';
import '../widgets/app_progress.dart';
import '../widgets/app_snackbar.dart';
import '../core/services/settings_service.dart';
import '../core/services/schedule_cache_service.dart';
import '../core/services/schedule_repository.dart';
import '../core/services/task_service.dart';
import '../core/utils/week_service.dart';

const _monthNames = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _weekDayNames = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

/// Главная страница TODO: подтягивание текущего расписания с помощью API или кеширования
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = NewsRepositoryImpl();
  List<News> _news = [];
  String? _error;
  bool _isLoading = true;

  // Сегодняшнее расписание и задачи
  List<Lesson> _todayLessons = [];
  List<PersonalTask> _todayTasks = [];
  bool _scheduleLoading = true;
  bool _showingTomorrow = false; // true если показываем «Завтра»

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body:  CustomScrollView(
        slivers: [
              SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildSemesterTimer(context),
                const SizedBox(height: 12),
                _buildTodayPanel(context),
                const SizedBox(height: 16),
                _buildNewsSection(_news),
                const SizedBox(height: 100)
              ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _repository.getNews();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.error != null) {
        _error = result.error;
        _news = [];
      } else {
        _error = null;
        _news = result.news;
      }
    });
  }

  Future<void> _loadTodayData() async {
    if (!mounted) return;
    setState(() => _scheduleLoading = true);

    final now = DateTime.now();
    final tasks = await TaskService.instance.loadTasksForDate(now);

    // Определяем фильтры
    String? groupIds;
    String? teacherNames;
    String? roomIds;
    try {
      final filterType = SettingsService.getLastFilterType();
      switch (filterType) {
        case 'group':
          groupIds = SettingsService.getLastGroupId();
          break;
        case 'teacher':
          teacherNames = SettingsService.getLastTeacherId();
          break;
        case 'audience':
          roomIds = SettingsService.getLastAudienceId();
          break;
        case 'personal':
          // Даже если фильтр «Личное», на дашборде показываем расписание сохранённой группы
          groupIds = SettingsService.getLastGroupId();
          break;
      }
    } catch (_) {}

    List<Lesson> lessons = [];
    bool isTomorrow = false;

    if (groupIds != null || teacherNames != null || roomIds != null) {
      try {
        // Загружаем пары на сегодня
        lessons = await _loadLessonsForDate(now, groupIds: groupIds, teacherNames: teacherNames, roomIds: roomIds);

        // Проверяем, не закончились ли все пары
        if (lessons.isNotEmpty) {
          final nowMinutes = now.hour * 60 + now.minute;
          final allOver = lessons.every((l) {
            final parts = l.timeEnd.split(':');
            if (parts.length < 2) return false;
            final endMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
            return nowMinutes >= endMin;
          });
          if (allOver) {
            // Все пары прошли — показываем завтра
            final tomorrow = now.add(const Duration(days: 1));
            final tmLessons = await _loadLessonsForDate(tomorrow, groupIds: groupIds, teacherNames: teacherNames, roomIds: roomIds);
            if (tmLessons.isNotEmpty) {
              lessons = tmLessons;
              isTomorrow = true;
            }
            // Если и завтра пусто — оставляем сегодняшние (пустые или прошедшие)
          }
        } else {
          // Сегодня пар нет — пробуем завтра
          final tomorrow = now.add(const Duration(days: 1));
          final tmLessons = await _loadLessonsForDate(tomorrow, groupIds: groupIds, teacherNames: teacherNames, roomIds: roomIds);
          if (tmLessons.isNotEmpty) {
            lessons = tmLessons;
            isTomorrow = true;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _todayTasks = tasks;
      _todayLessons = lessons;
      _showingTomorrow = isTomorrow;
      _scheduleLoading = false;
    });
  }

  Future<List<Lesson>> _loadLessonsForDate(DateTime date, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) async {
    final week = WeekService.getWeekForDate(date);
    final result = await ScheduleCacheService.instance.get(
      ApiClient(),
      week,
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final lessons = result.lessons.where((l) {
      if (l.date != null) {
        final normalized = l.date!.replaceAll('-', '.').replaceAll('/', '.');
        return normalized == dateStr;
      }
      return l.dayOfWeek == date.weekday;
    }).toList();
    lessons.sort((a, b) => a.timeStart.compareTo(b.timeStart));
    return lessons;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
        title: const Text('Расписание ОмГТУ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showAppBarPopup(context),
          ),
        ],
      );
  }

  void _showAppBarPopup(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2E).withOpacity(0.85)
                        : Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.06),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PopupTile(
                        icon: Icons.settings_rounded,
                        label: 'Настройки',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.push('/settings');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    if (context.mounted) {
      AppSnackBar.success(context, 'Выход выполнен');
    }
  }

  Widget _buildQuickActions(BuildContext context, Lesson? nextLesson) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 4;
        const spacing = 8.0;
        const totalSpacing = spacing * (count - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / count;
        final itemHeight = itemWidth / 0.85;
        return SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.primaryLight,
                  title: 'Сегодня',
                  subtitle: nextLesson?.timeStart ?? '08:30',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.groups_rounded,
                  iconColor: AppColors.success,
                  title: 'Группа',
                  subtitle: 'ИУ5-31б',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.warning,
                  title: 'Препод.',
                  subtitle: 'Петров В.В.',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  title: 'Карты',
                  subtitle: '🗺️',
                  onTap: () => context.go('/maps'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(int completedTasks, int totalTasks, int minutesToNext) {
    return Padding(
      padding: const EdgeInsetsGeometry.all(16),
      child: Row(
        children: [
          const Expanded(
            child: BaseContainer(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Посещено пар', style: _subtitleStyle),
                  SizedBox(height: 4),
                  Text('14/18', style: _boldPrimaryStyle),
                  SizedBox(height: 8),
                  AppProgress(value: 77.8, height: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BaseContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Задачи', style: _subtitleStyle),
                  const SizedBox(height: 4),
                  Text('$completedTasks/$totalTasks', style: _boldSuccessStyle),
                  const SizedBox(height: 8),
                  AppProgress(value: totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0, height: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BaseContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('До следующей', style: _subtitleStyle),
                  const SizedBox(height: 4),
                  Text('$minutesToNextм', style: _boldWarningStyle),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * 0.5,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context, List<Lesson> todayLessons) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthNames[now.month - 1]}, ${_weekDayNames[now.weekday - 1]}';
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 16), 
      child: BaseContainer(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Расписание на сегодня',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: todayLessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ScheduleRow(
                  lesson: todayLessons[index],
                  index: index,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go('/schedule'),
              icon: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
              label: Text(
                'Показать всё расписание',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterTimer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    // Конец весеннего семестра — 30 июня, осеннего — 31 декабря
    final semesterEnd = now.month <= 6
        ? DateTime(now.year, 6, 30)
        : DateTime(now.year, 12, 31);
    final diff = semesterEnd.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    // Выбираем фразу
    String phrase;
    if (days <= 0) {
      phrase = 'Каникулы!!! 🎉';
    } else if (days <= 7) {
      phrase = 'Финишная прямая... 🏃';
    } else if (days <= 30) {
      phrase = 'Скоро свобода! 💪';
    } else if (days <= 60) {
      phrase = 'Половина пути ⏳';
    } else {
      phrase = 'Терпим... 📚';
    }

    final daysWord = _pluralDays(days);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.primary.withOpacity(0.06),
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.primary.withOpacity(0.06),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.primary.withOpacity(0.18),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    days <= 0
                        ? 'Семестр окончен'
                        : 'До конца семестра $days $daysWord $hoursч',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (days > 0)
              Text(
                '$days',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _pluralDays(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }

  /// Проверяет, идёт ли пара прямо сейчас.
  bool _isLessonNow(Lesson lesson) {
    if (_showingTomorrow) return false;
    final now = DateTime.now();
    try {
      final sp = lesson.timeStart.split(':');
      final ep = lesson.timeEnd.split(':');
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      final nowMin = now.hour * 60 + now.minute;
      return nowMin >= startMin && nowMin < endMin;
    } catch (_) {
      return false;
    }
  }

  /// Показать BottomSheet с деталями пары (как на странице расписания).
  void _showLessonDetailsFromDashboard(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DashboardLessonSheet(lesson: lesson),
    );
  }

  /// Группирует пары по временному слоту и возвращает виджеты.
  /// Если на один слот приходится несколько пар (подгруппы) — горизонтальный скролл.
  List<Widget> _buildGroupedLessonTiles() {
    // Группируем по timeStart
    final Map<String, List<Lesson>> groups = {};
    for (final lesson in _todayLessons) {
      final key = lesson.timeStart;
      groups.putIfAbsent(key, () => []).add(lesson);
    }

    final List<Widget> widgets = [];
    for (final entry in groups.entries) {
      final lessons = entry.value;
      if (lessons.length == 1) {
        final lesson = lessons.first;
        widgets.add(_TodayLessonTile(
          lesson: lesson,
          isCurrent: _isLessonNow(lesson),
          onTap: () => _showLessonDetailsFromDashboard(lesson),
        ));
      } else {
        // Несколько пар на один слот — горизонтальный скролл
        widgets.add(_TimeSlotScrollView(
          lessons: lessons,
          isCurrentCheck: _isLessonNow,
          onTap: _showLessonDetailsFromDashboard,
        ));
      }
    }
    return widgets;
  }

  Widget _buildTodayPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    // Определяем дату для заголовка
    final displayDate = _showingTomorrow ? now.add(const Duration(days: 1)) : now;
    final dateStr = '${displayDate.day} ${_monthNames[displayDate.month - 1]}, ${_weekDayNames[displayDate.weekday - 1]}';
    final headerTitle = _showingTomorrow ? 'Завтра' : 'Сегодня';
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final hasLessons = _todayLessons.isNotEmpty;
    final hasTasks = _todayTasks.isNotEmpty;
    final hasContent = hasLessons || hasTasks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BaseContainer(
        isGlass: isDark,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с датой
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _showingTomorrow ? Icons.event_rounded : Icons.today_rounded,
                    size: 20,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => context.go('/schedule'),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Расписание',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_scheduleLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: primary,
                    ),
                  ),
                ),
              )
            else if (!hasContent)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 40,
                        color: onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'На ${ _showingTomorrow ? "завтра" : "сегодня" } ничего не запланировано',
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Пары — показываем ВСЕ
              if (hasLessons) ...[
                Row(
                  children: [
                    Icon(Icons.school_rounded, size: 14, color: primary),
                    const SizedBox(width: 6),
                    Text(
                      'Пары (${_todayLessons.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._buildGroupedLessonTiles(),
              ],

              // Разделитель
              if (hasLessons && hasTasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: theme.dividerColor),
                ),

              // Задачи — показываем ВСЕ
              if (hasTasks) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.taskAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Задачи (${_todayTasks.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB49AFF) : AppColors.taskAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(_todayTasks.length, (i) {
                  final task = _todayTasks[i];
                  return _TodayTaskTile(task: task);
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

Widget _buildNewsSection(List<News> news) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 12),
        child: Text(
          'Новости ОмГТУ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      Container(
        height: 380,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: _isLoading
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                padding: const EdgeInsets.only(left: 16),
                itemBuilder: (context, index) => SizedBox(
                  width: 300,
                  child: _NewsSkeletonCard(isDark: isDark),
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
              )
            : news.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.newspaper_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Новостей пока нет',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: news.length,
                    itemBuilder: (context, index) => SizedBox(
                      width: 300,
                      child: _NewsCard(news: news[index]),
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                  ),
      ),
    ],
  );
}

  static const TextStyle _subtitleStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const TextStyle _boldPrimaryStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static const TextStyle _boldSuccessStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );
  static const TextStyle _boldWarningStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.warning,
  );
  
}

class _PopupTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PopupTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.spacingMd),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final Lesson lesson;
  final int index;

  const _ScheduleRow({required this.lesson, this.index = 0});

  @override
  Widget build(BuildContext context) {
    Color dotColor = AppColors.success;
    if (index == 0) dotColor = AppColors.error;
    if (index == 1) dotColor = AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                lesson.timeStart,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.timeEnd,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              height: 1,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${lesson.teacher} • ${lesson.room}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Призрачный (skeleton) шаблон карточки новости для состояния загрузки
class _NewsSkeletonCard extends StatefulWidget {
  final bool isDark;
  const _NewsSkeletonCard({required this.isDark});

  @override
  State<_NewsSkeletonCard> createState() => _NewsSkeletonCardState();
}

class _NewsSkeletonCardState extends State<_NewsSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Container(
          margin: const EdgeInsets.only(left: 16, bottom: 24, top: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder — верхняя часть, flex 3
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: _shimmerBox(double.infinity, double.infinity, 0, shimmerValue),
                ),
              ),
              // Нижняя часть — flex 2
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(double.infinity, 13, 6, shimmerValue),
                      const SizedBox(height: 8),
                      _shimmerBox(200, 13, 6, shimmerValue),
                      const SizedBox(height: 8),
                      _shimmerBox(140, 13, 6, shimmerValue),
                      const Spacer(),
                      _shimmerBox(80, 13, 6, shimmerValue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(
      double width, double height, double radius, double shimmerValue) {
    final baseColor =
        widget.isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE8EBF0);
    final highlightColor =
        widget.isDark ? const Color(0xFF3A3A3E) : const Color(0xFFF5F7FA);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * shimmerValue, 0),
          end: Alignment(-1.0 + 2.0 * shimmerValue + 1.0, 0),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final News news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(news.url)),
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 24, top: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение сверху
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      NewsRepositoryImpl.imageUrl(news.id),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: primary,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('News image error for id=${news.id}: $error');
                        return Container(
                          color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: secondaryText.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                    // Градиент снизу
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Дата
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.date,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Заголовок и кнопка — фиксированная нижняя часть
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        news.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Читать',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Акцентный цвет для типа занятия.
Color _lessonTypeColor(LessonType type, bool isDark) {
  switch (type) {
    case LessonType.lecture:
      return isDark ? const Color(0xFF6AADFF) : const Color(0xFF4A8FD9);
    case LessonType.lab:
      return isDark ? const Color(0xFFE8B44C) : const Color(0xFFC9962E);
    case LessonType.retake:
      return isDark ? const Color(0xFFE07676) : const Color(0xFFCC5555);
    case LessonType.practice:
      return isDark ? const Color(0xFF4ED9A0) : const Color(0xFF3EA87C);
    case LessonType.personal:
      return isDark ? const Color(0xFFA98BFA) : const Color(0xFF8B6FD4);
    case LessonType.exam:
      return isDark ? const Color(0xFFFF7A7A) : const Color(0xFFD94444);
    case LessonType.examPrep:
      return isDark ? const Color(0xFFFFB86A) : const Color(0xFFD9882E);
  }
}

/// Горизонтальный скролл для пар на один временной слот (подгруппы).
class _TimeSlotScrollView extends StatelessWidget {
  final List<Lesson> lessons;
  final bool Function(Lesson) isCurrentCheck;
  final void Function(Lesson) onTap;

  const _TimeSlotScrollView({
    required this.lessons,
    required this.isCurrentCheck,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 68,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.92),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TodayLessonTile(
                lesson: lesson,
                isCurrent: isCurrentCheck(lesson),
                onTap: () => onTap(lesson),
                noPadding: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Плитка пары в панели «Сегодня» на главной.
class _TodayLessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isCurrent;
  final VoidCallback? onTap;
  final bool noPadding;

  const _TodayLessonTile({
    required this.lesson,
    this.isCurrent = false,
    this.onTap,
    this.noPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final typeColor = _lessonTypeColor(lesson.type, isDark);

    final hasSubgroup = lesson.subgroup != null && lesson.subgroup!.isNotEmpty;

    return Padding(
      padding: noPadding ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent
                ? primary.withValues(alpha: isDark ? 0.12 : 0.08)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? primary.withValues(alpha: isDark ? 0.5 : 0.35)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : primary.withValues(alpha: 0.10),
              width: isCurrent ? 1.5 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Время
              Column(
                children: [
                  Text(
                    lesson.timeStart,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  Text(
                    lesson.timeEnd,
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isCurrent ? 0.9 : 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Предмет и детали
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.subject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.teacher != null && lesson.teacher!.isNotEmpty)
                      Text(
                        '${lesson.teacher}${lesson.room != null && lesson.room!.isNotEmpty ? ' • ${lesson.room}' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Подгруппа — заметный бейдж
              if (hasSubgroup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    lesson.subgroup!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ED9A0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ED9A0).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Плитка задачи в панели «Сегодня» на главной.
class _TodayTaskTile extends StatelessWidget {
  final PersonalTask task;
  const _TodayTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final accent = isDark ? const Color(0xFFB49AFF) : AppColors.taskAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? accent.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              task.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: task.completed ? AppColors.success : accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: task.completed
                          ? onSurface.withValues(alpha: 0.5)
                          : onSurface,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.audience != null && task.audience!.isNotEmpty)
                    Text(
                      task.audience!,
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              task.time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet с деталями пары — открывается с главной страницы.
class _DashboardLessonSheet extends StatelessWidget {
  final Lesson lesson;

  const _DashboardLessonSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final typeColor = _lessonTypeColor(lesson.type, isDark);
    final buildingInfo = BuildingData.findByAuditorium(lesson.room);

    Widget sheetContent = Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? null : theme.cardColor,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
              )
            : Border(
                top: BorderSide(color: theme.dividerColor),
                left: BorderSide(color: theme.dividerColor),
                right: BorderSide(color: theme.dividerColor),
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Название предмета
          Text(
            lesson.subject,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 20),

          // Время + Аудитория — две карточки рядом
          Row(
            children: [
              // Время
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: isDark ? 0.1 : 0.06),
                        primary.withValues(alpha: isDark ? 0.05 : 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.access_time_rounded, color: primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lesson.timeStart} – ${lesson.timeEnd}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_durationMinutes(lesson.timeStart, lesson.timeEnd)} мин',
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Аудитория
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withValues(alpha: isDark ? 0.1 : 0.06),
                        AppColors.error.withValues(alpha: isDark ? 0.04 : 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.room ?? '—',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lesson.building != null && lesson.building!.isNotEmpty)
                              Text(
                                lesson.building!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Преподаватель
          _DashboardDetailRow(
            icon: Icons.person_rounded,
            iconColor: AppColors.success,
            label: 'Преподаватель',
            value: lesson.teacher ?? '—',
          ),

          // Группа
          _DashboardDetailRow(
            icon: Icons.group_rounded,
            iconColor: primary,
            label: 'Группа',
            value: () {
              final parts = [lesson.group, lesson.stream]
                  .where((s) => s != null && s.isNotEmpty);
              return parts.isEmpty ? '' : parts.join(' • ');
            }(),
          ),

          // Корпус + кнопка на карту
          if (buildingInfo != null) ...[
            _DashboardDetailRow(
              icon: Icons.apartment_rounded,
              iconColor: primary,
              label: 'Корпус',
              value: '${buildingInfo.name} — ${buildingInfo.address}',
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openMapChooser(context, buildingInfo),
                icon: const Icon(Icons.map_rounded, size: 20),
                label: const Text('Показать на карте'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (isDark) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: sheetContent,
        ),
      );
    }
    return sheetContent;
  }

  static int _durationMinutes(String start, String end) {
    try {
      final sp = start.split(':');
      final ep = end.split(':');
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      return endMin - startMin;
    } catch (_) {
      return 90;
    }
  }

  void _openMapChooser(BuildContext context, BuildingInfo info) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget mapContent = Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? null : theme.cardColor,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: isDark
                ? Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.5,
                    ),
                  )
                : Border(
                    top: BorderSide(color: theme.dividerColor),
                    left: BorderSide(color: theme.dividerColor),
                    right: BorderSide(color: theme.dividerColor),
                  ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Показать на карте',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                info.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _DashboardMapButton(
                icon: Icons.map_rounded,
                label: '2ГИС',
                color: const Color(0xFF34A853),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final query = Uri.encodeComponent('Омск, ${info.address}');
                  launchUrl(Uri.parse('https://2gis.ru/omsk/search/$query'),
                      mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 10),
              _DashboardMapButton(
                icon: Icons.navigation_rounded,
                label: 'Яндекс Карты',
                color: const Color(0xFFFC3F1D),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final query = Uri.encodeComponent('Омск, ${info.address}');
                  launchUrl(Uri.parse('https://yandex.ru/maps/?text=$query'),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        );

        if (isDark) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: mapContent,
            ),
          );
        }
        return mapContent;
      },
    );
  }
}

class _DashboardDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DashboardDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty || value == '—') return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardMapButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}