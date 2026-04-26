import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/core/services/schedule_news.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
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
import 'package:cached_network_image/cached_network_image.dart';


const _host = '172.20.10.8'; //localhost
// const _host = 'localhost';

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

    // Загружаем задачи на сегодня
    final now = DateTime.now();
    final tasks = await TaskService.instance.loadTasksForDate(now);

    // Загружаем расписание на сегодня из кеша/API
    List<Lesson> lessons = [];
    try {
      final filterType = SettingsService.getLastFilterType();
      String? groupIds;
      String? teacherNames;
      String? roomIds;
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
      }
      if (groupIds != null || teacherNames != null || roomIds != null) {
        final week = WeekService.getWeekForDate(now);
        final result = await ScheduleCacheService.instance.get(
          ApiClient(),
          week,
          groupIds: groupIds,
          teacherNames: teacherNames,
          roomIds: roomIds,
        );
        // Фильтруем только сегодняшние пары
        final todayStr = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
        lessons = result.lessons.where((l) {
          if (l.date != null) {
            // Формат даты из API может быть yyyy.MM.dd или другой
            final normalized = l.date!.replaceAll('-', '.').replaceAll('/', '.');
            return normalized == todayStr;
          }
          return l.dayOfWeek == now.weekday;
        }).toList();
        lessons.sort((a, b) => a.timeStart.compareTo(b.timeStart));
      }
    } catch (_) {
      // Если не удалось загрузить расписание — просто показываем пустой список
    }

    if (!mounted) return;
    setState(() {
      _todayTasks = tasks;
      _todayLessons = lessons;
      _scheduleLoading = false;
    });
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
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.75),
                        Colors.white.withOpacity(0.55),
                      ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.8),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
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
                  // Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.6)),
                  // _PopupTile(
                  //   icon: Icons.notifications_rounded,
                  //   label: 'Уведомления',
                  //   onTap: () {
                  //     Navigator.of(ctx).pop();
                  //   },
                  // ),
                  // Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.6)),
                  // _PopupTile(
                  //   icon: Icons.logout_rounded,
                  //   label: 'Выйти',
                  //   onTap: () {
                  //     Navigator.of(ctx).pop();
                  //     _logout(context);
                  //   },
                  // ),
                ],
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

  Widget _buildTodayPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthNames[now.month - 1]}, ${_weekDayNames[now.weekday - 1]}';
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
                    Icons.today_rounded,
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
                        'Сегодня',
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
                // Кнопка перехода к расписанию
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
                        'На сегодня ничего не запланировано',
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
              // Пары
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
                ...List.generate(_todayLessons.length.clamp(0, 5), (i) {
                  final lesson = _todayLessons[i];
                  return _TodayLessonTile(lesson: lesson);
                }),
                if (_todayLessons.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ещё ${_todayLessons.length - 5}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],

              // Разделитель
              if (hasLessons && hasTasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: theme.dividerColor),
                ),

              // Задачи
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
                ...List.generate(_todayTasks.length.clamp(0, 5), (i) {
                  final task = _todayTasks[i];
                  return _TodayTaskTile(task: task);
                }),
                if (_todayTasks.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ещё ${_todayTasks.length - 5}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
        height: 410,
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
        return BaseContainer(
          margin: const EdgeInsets.only(left: 0, bottom: 24, top: 10),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Row(
                children: [
                  _shimmerBox(32, 32, 10, shimmerValue),
                  const SizedBox(width: 8),
                  _shimmerBox(100, 12, 6, shimmerValue),
                ],
              ),
              const SizedBox(height: 16),
              // Title skeleton lines
              _shimmerBox(double.infinity, 14, 6, shimmerValue),
              const SizedBox(height: 8),
              _shimmerBox(200, 14, 6, shimmerValue),
              const SizedBox(height: 8),
              _shimmerBox(140, 14, 6, shimmerValue),
              const SizedBox(height: 16),
              // Image skeleton
              _shimmerBox(double.infinity, 180, 14, shimmerValue),
              const SizedBox(height: 16),
              // Button skeleton
              Align(
                alignment: Alignment.centerRight,
                child: _shimmerBox(100, 28, 14, shimmerValue),
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

  static const double _imageHeight = 180;
  static const double _titleHeight = 54;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: 0.6);

    return BaseContainer(
      isGlass: isDark,
      margin: const EdgeInsets.only(left: 16, bottom: 24, top: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя часть с датой и иконкой
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  news.date,
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: _titleHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                news.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            height: _imageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : primary.withValues(alpha: 0.10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'http://$_host:8000/api/news/images/${news.id}',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => Container(
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
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: secondaryText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Не удалось загрузить',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(news.url)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Читать дальше',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Плитка пары в панели «Сегодня» на главной.
class _TodayLessonTile extends StatelessWidget {
  final Lesson lesson;
  const _TodayLessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : primary.withValues(alpha: 0.10),
          ),
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
              height: 32,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.4),
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
          ],
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