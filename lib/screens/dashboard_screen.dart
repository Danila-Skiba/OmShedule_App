import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/core/services/news_service.dart';
import '../constants/app_colors.dart';
import '../data/building_data.dart';
import '../data/schedule_data.dart';
import '../constants/app_constants.dart';
import '../widgets/base_container.dart';
import '../models/lesson.dart';
import '../models/news.dart';
import '../models/personal_task.dart';
import '../ui/adaptive/adaptive_exports.dart';
import '../core/services/settings_service.dart';
import '../core/services/schedule_cache_service.dart';
import '../core/services/schedule_repository.dart';
import '../core/services/task_service.dart';
import '../core/utils/platform_utils.dart';
import '../core/utils/week_service.dart';

const _monthNames = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _weekDayNames = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

/// Главная страница: панель «Сегодня» с парами и задачами плюс лента новостей.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Раздел новостей на сайте вуза — открывается по кнопке «Все».
const String _newsSiteUrl = 'https://www.omgtu.ru/news/';

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  List<News> _news = [];
  bool _isLoading = true;

  // Сегодняшнее расписание и задачи
  List<Lesson> _todayLessons = [];
  List<PersonalTask> _todayTasks = [];
  bool _scheduleLoading = true;
  bool _showingTomorrow = false; // true если показываем «Завтра»

  @override
  void initState() {
    super.initState();
    // На iOS «запуск» приложения почти всегда возврат из фона, а не холодный
    // старт: initState больше не вызывается, и без слушателя жизненного цикла
    // лента застывала на том, что загрузилось при первой установке.
    WidgetsBinding.instance.addObserver(this);
    // Задачи меняются и на своей вкладке: без подписки добавленная там задача
    // не появлялась в панели «Сегодня», пока приложение не уйдёт в фон и не
    // вернётся.
    TaskService.instance.addListener(_onTasksChanged);
    _loadData();
    _loadTodayData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TaskService.instance.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;
    // Расписание перезагружать незачем — оно не изменилось.
    _loadTodayTasks();
  }

  Future<void> _loadTodayTasks() async {
    try {
      final tasks = await TaskService.instance.loadTasksForDate(
        _showingTomorrow
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.now(),
      );
      if (mounted) setState(() => _todayTasks = tasks);
    } catch (e) {
      debugPrint('Dashboard: не удалось перечитать задачи: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    // Решение «идти ли в сеть» принимает NewsService; здесь просто повод.
    _loadData();
    _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: _buildAppBar(context),
      body:  CustomScrollView(
        slivers: [
          // Автообновление ограничено часом, поэтому нужен ручной способ
          // подтянуть ленту прямо сейчас.
          if (isIOS) // iOS
            CupertinoSliverRefreshControl(
              onRefresh: () => _loadData(forceRefresh: true),
            ),
              SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Сначала мгновенно показываем сохранённую ленту — скелетоны остаются
    // только для первого запуска, когда кеша ещё нет.
    final cached = await NewsService.instance.cachedNews();
    if (!mounted) return;
    if (cached.isNotEmpty) {
      setState(() {
        _news = cached;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    final result = await NewsService.instance.getNews(
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      // При ошибке сети сервис уже вернул устаревший кеш; затирать показанную
      // ленту пустым списком нельзя — иначе офлайн даёт «Новостей пока нет».
      if (result.error == null) {
        _news = result.news;
      } else if (_news.isEmpty) {
        _news = cached;
      }
    });
  }

  Future<void> _loadTodayData() async {
    if (!mounted) return;
    setState(() => _scheduleLoading = true);

    // Всё тело — под try/finally: любое исключение по пути (чтение задач,
    // разбор времени пары) раньше проскакивало мимо setState, и панель
    // «Сегодня» оставалась в состоянии загрузки навсегда.
    List<PersonalTask> tasks = const [];
    try {
      tasks = await TaskService.instance.loadTasksForDate(DateTime.now());
    } catch (e) {
      debugPrint('Dashboard: не удалось прочитать задачи: $e');
    }

    final now = DateTime.now();

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
    } catch (e) {
      debugPrint('Dashboard: не удалось прочитать сохранённый фильтр: $e');
    }

    // Справочники обновляются — сохранённое значение могло исчезнуть
    if (!ScheduleData.hasGroup(groupIds)) groupIds = null;
    if (!ScheduleData.hasPerson(teacherNames)) teacherNames = null;
    if (!ScheduleData.hasAuditorium(roomIds)) roomIds = null;

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
      } catch (e) {
        // Панель просто останется без пар: расписание грузится и на своей
        // вкладке, а падать из-за него главная не должна.
        debugPrint('Dashboard: расписание на сегодня не загружено: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _todayTasks = tasks;
      _todayLessons = lessons;
      _showingTomorrow = isTomorrow;
      _scheduleLoading = false;
    });
  }

  /// Отметить задачу выполненной / вернуть в работу прямо с главной.
  ///
  /// Список обновляется сразу, не дожидаясь записи файла: нажатие должно
  /// отзываться в том же кадре. Если запись не удалась — возвращаем прежнее
  /// состояние, иначе галочка врала бы до следующей загрузки.
  Future<void> _toggleTaskCompleted(PersonalTask task) async {
    final index = _todayTasks.indexWhere((t) => t.id == task.id);
    if (index < 0) return;

    final previous = _todayTasks[index];
    HapticFeedback.lightImpact();
    setState(() {
      _todayTasks = List<PersonalTask>.from(_todayTasks)
        ..[index] = previous.copyWith(completed: !previous.completed);
    });

    try {
      await TaskService.instance.toggleCompleted(task.id);
    } catch (e) {
      debugPrint('Dashboard: не удалось сохранить отметку задачи: $e');
      if (!mounted) return;
      final rollbackIndex = _todayTasks.indexWhere((t) => t.id == task.id);
      if (rollbackIndex < 0) return;
      setState(() {
        _todayTasks = List<PersonalTask>.from(_todayTasks)
          ..[rollbackIndex] = previous;
      });
      AppSnackBar.error(context, 'Не удалось сохранить отметку');
    }
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

  AppAppBar _buildAppBar(BuildContext context) {
    return AppAppBar(
      title: 'Расписание ОмГТУ',
      useNativeToolbar: true,
      actions: [
        AppAppBarAction(
          iosSymbol: AppIcons.more.symbol,
          icon: isIOS ? CupertinoIcons.ellipsis : AppIcons.more.icon, // iOS
          onPressed: () => _showAppBarPopup(context),
        ),
      ],
    );
  }

  void _showAppBarPopup(BuildContext context) {
    // iOS — CupertinoActionSheet
    if (isIOS) { // iOS
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/settings');
              },
              child: const Text('Настройки'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
        ),
      );
      return;
    }

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
                        ? const Color(0xFF2A2A2E).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
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
      enableDrag: true, // свайп вниз для закрытия
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

            // Загрузка → «ничего не запланировано» → содержимое сменяют друг
            // друга плавно, а не подменяются в одном кадре. Ключ — только имя
            // состояния: пока показано содержимое, правки внутри него
            // (например отметка «выполнено») идут без перекрёстного затухания.
            // AnimatedSize догоняет высоту панели, иначе карточка прыгала бы.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(
                    _scheduleLoading
                        ? 'loading'
                        : hasContent
                            ? 'content'
                            : 'empty',
                  ),
                  child: _buildTodayPanelBody(
                    theme: theme,
                    isDark: isDark,
                    primary: primary,
                    onSurface: onSurface,
                    hasLessons: hasLessons,
                    hasTasks: hasTasks,
                    hasContent: hasContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Содержимое панели «Сегодня» под заголовком: лоадер, заглушка или
  /// список пар и задач.
  Widget _buildTodayPanelBody({
    required ThemeData theme,
    required bool isDark,
    required Color primary,
    required Color onSurface,
    required bool hasLessons,
    required bool hasTasks,
    required bool hasContent,
  }) {
    if (_scheduleLoading) {
      return Center( // iOS
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: buildLoader(radius: 12, strokeWidth: 2.2, color: primary),
        ),
      );
    }

    if (!hasContent) {
      return Center(
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
                'На ${_showingTomorrow ? "завтра" : "сегодня"} ничего не запланировано',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              const Icon(Icons.check_circle_outline_rounded,
                  size: 14, color: AppColors.taskAccent),
              const SizedBox(width: 6),
              Text(
                'Задачи (${_todayTasks.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFB49AFF)
                      : AppColors.taskAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_todayTasks.length, (i) {
            final task = _todayTasks[i];
            return _TodayTaskTile(
              task: task,
              onToggleCompleted: () => _toggleTaskCompleted(task),
            );
          }),
        ],
      ],
    );
  }

Widget _buildNewsSection(List<News> news) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primary = theme.colorScheme.primary;
  final onSurface = theme.colorScheme.onSurface;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Заголовок секции — в стиле панели «Сегодня»
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.newspaper_rounded, size: 20, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Новости',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  Text(
                    'Что происходит в университете',
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
                onTap: () => openExternalUrl(_newsSiteUrl),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Все',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 300,
        child: _isLoading
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) => SizedBox(
                  width: 270,
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
                            color: onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Новостей пока нет',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: news.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => SizedBox(
                      width: 270,
                      child: _NewsCard(news: news[index]),
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                  ),
      ),
    ],
  );
}

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
          margin: const EdgeInsets.only(bottom: 14, top: 2),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Обложка во всю карточку
              _shimmerBox(double.infinity, double.infinity, 0, shimmerValue),
              // Строки заголовка снизу
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _shimmerBox(double.infinity, 13, 6, shimmerValue),
                    const SizedBox(height: 8),
                    _shimmerBox(160, 13, 6, shimmerValue),
                    const SizedBox(height: 14),
                    _shimmerBox(70, 11, 6, shimmerValue),
                  ],
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

    return GestureDetector(
      onTap: () => openExternalUrl(news.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : primary.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Обложка во всю карточку
              _buildCover(context, isDark, primary),

              // Затемнение снизу — под текст
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x1A000000),
                      Color(0xD9000000),
                    ],
                    stops: [0.35, 0.55, 1.0],
                  ),
                ),
              ),

              // Дата — «стеклянная» плашка
              Positioned(
                top: 12,
                left: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            news.date,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Заголовок и «Читать» поверх обложки
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.32,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Читать',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Обложка новости: картинка либо запасная заливка с иконкой.
  Widget _buildCover(BuildContext context, bool isDark, Color primary) {
    final fallbackColor = primary.withValues(alpha: isDark ? 0.22 : 0.18);

    Widget placeholder({IconData? icon}) => Container(
          color: fallbackColor,
          child: icon == null
              ? null
              : Center(
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
        );

    if (news.image == null || news.image!.isEmpty) {
      return placeholder(icon: Icons.newspaper_rounded);
    }

    return CachedNetworkImage(
      imageUrl: news.image!,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      placeholder: (context, url) => Container( // iOS
        color: fallbackColor,
        child: Center(
          child: buildLoader(radius: 12, strokeWidth: 2.2, color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('News image error for id=${news.id}: $error');
        return placeholder(icon: Icons.broken_image_outlined);
      },
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

  /// Нажатие по кружку слева — отметка «выполнено».
  final VoidCallback? onToggleCompleted;

  const _TodayTaskTile({required this.task, this.onToggleCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final accent = isDark ? const Color(0xFFB49AFF) : AppColors.taskAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
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
            // Зона нажатия шире самой иконки (20 px мало для пальца): отступ
            // отъедается у внешнего Padding, поэтому плитка не разъезжается.
            GestureDetector(
              onTap: onToggleCompleted,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    task.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    // Ключ по состоянию — иначе AnimatedSwitcher считает иконку
                    // той же самой и подменяет её без анимации.
                    key: ValueKey(task.completed),
                    size: 20,
                    color: task.completed ? AppColors.success : accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
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
    final buildingInfo = BuildingData.findByAuditorium(lesson.room);

    Widget sheetContent = Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? null : theme.cardColor,
        // В тёмной теме лист лежит поверх размытия и раньше был почти
        // прозрачным — содержимое под ним просвечивало и сливалось.
        // Блик сверху оставляем, но подмешиваем его к непрозрачному цвету
        // карточки, а не кладём голым белым с альфой.
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.10),
                    theme.cardColor,
                  ),
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.05),
                    theme.cardColor,
                  ),
                ],
              )
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
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
                  color: Colors.black.withValues(alpha: 0.08),
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

          // Название предмета — обычным текстовым цветом (белым в тёмной теме,
          // тёмным в светлой), как и в такой же шторке на экране расписания.
          Text(
            lesson.subject,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Время + Аудитория — две карточки рядом
          Row(
            children: [
              // Время
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.access_time_rounded, color: primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lesson.timeStart}–${lesson.timeEnd}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.all(12),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.room ?? '—',
                              style: TextStyle(
                                fontSize: 13,
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
              child: isIOS // iOS
                  ? CupertinoButton(
                      onPressed: () => _openMapChooser(context, buildingInfo),
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                      padding: EdgeInsets.zero,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded, size: 20, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text('Показать на карте', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
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
    // iOS — CupertinoActionSheet
    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Показать на карте'),
          message: Text(info.address),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                // _openIn2GIS(info);
              },
              child: const Text('2ГИС'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                // _openInYandexMaps(info);
              },
              child: const Text('Яндекс Карты'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
        ),
      );
      return;
    }

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
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: isDark
                ? Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
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
                      color: Colors.black.withValues(alpha: 0.08),
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
                  openExternalUrl('https://2gis.ru/omsk/search/$query');
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
                  openExternalUrl('https://yandex.ru/maps/?text=$query');
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