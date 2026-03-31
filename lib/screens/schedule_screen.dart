import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/widgets/base_container.dart';
import 'package:omstu_schedule/data/schedule_data.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../core/services/settings_service.dart';
import '../core/services/task_service.dart';
import '../core/state/filter_controller.dart';
import '../core/state/schedule_week_controller.dart';
import '../core/utils/week_service.dart';
import '../models/lesson.dart';
import '../models/personal_task.dart';
import '../models/schedule_type.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/personal_task_card.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _view = 'today';
  late ScheduleType _scheduleType;
  Lesson? _selectedLesson;
  late ScheduleWeekController _weekController;
  late FilterController _filterController;
  List<PersonalTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _filterController = FilterController();
    _applyDefaultsFromProfile();
    _filterController.addListener(_onFilterChanged);
    _weekController = ScheduleWeekController();
    _weekController.addListener(_onWeekControllerChanged);
    TaskService.instance.addListener(_onTasksChanged);
    _syncFiltersToController();
    _loadTasks();
  }

  @override
  void dispose() {
    TaskService.instance.removeListener(_onTasksChanged);
    _filterController.removeListener(_onFilterChanged);
    _filterController.dispose();
    _weekController.removeListener(_onWeekControllerChanged);
    _weekController.dispose();
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  void _onTasksChanged() {
    if (_filterController.isPersonal && mounted) _loadTasks();
  }
  void _onWeekControllerChanged() {
    setState(() {});
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final week = _weekController.currentWeek;
    final tasks = await TaskService.instance.getTasksForPeriod(
      week.startDate,
      week.endDate,
    );
    if (mounted) setState(() => _tasks = tasks);
  }

  /// Передаёт в репозиторий только выбранный фильтр — без суммирования.
  void _syncFiltersToController() {
    final ft = _filterController.currentFilterType.value;
    String? groupIds;
    String? teacherNames;
    String? roomIds;
    switch (ft) {
      case FilterType.group:
        final v = _filterController.selectedGroup.value;
        groupIds = v;
        break;
      case FilterType.teacher:
        final v = _filterController.selectedTeacher.value;
        teacherNames = v;
        break;
      case FilterType.audience:
        final v = _filterController.selectedAudience.value;
        roomIds = v;
        break;
      case FilterType.personal:
        break;
    }
    _weekController.setFilters(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
  }

  void _applyDefaultsFromProfile() {
    final role = SettingsService.getProfileRole();
    if (role == 'student') {
      _scheduleType = ScheduleType.group;
      _filterController.updateGroup(
      ScheduleData.getgroups.keys.first,
      );
      _filterController.updateTeacher(null);
      _filterController.updateAudience(null);
    } else {
      _scheduleType = ScheduleType.teacher;
      _filterController.updateTeacher(
        SettingsService.getDefaultTeacherId() ??
            ScheduleData.getpersons.keys.first,
      );
      _filterController.updateGroup(null);
      _filterController.updateAudience(null);
    }
    _filterController.setFilterType(
      _scheduleType == ScheduleType.group
          ? FilterType.group
          : FilterType.teacher,
    );
  }

  List<Lesson> get _filteredLessons => _weekController.lessons;

  String get _filterIndicator {
    final v = _filterController.selectedValue;
    if (v != null) return v;
    if (_filterController.isPersonal) return 'Личное';
    switch (_filterController.currentFilterType.value) {
      case FilterType.group:
        return 'Выберите группу';
      case FilterType.teacher:
        return 'Выберите преподавателя';
      case FilterType.audience:
        return 'Выберите аудиторию';
      case FilterType.personal:
        return 'Личное';
    }
  }

  static String _dateStr(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  List<PersonalTask> _tasksForDate(DateTime date) {
    final s = _dateStr(date);
    return _tasks.where((t) => t.date == s).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  void _openSelectForCurrentFilter() {
    switch (_filterController.currentFilterType.value) {
      case FilterType.group:
        _openSelect('group');
        break;
      case FilterType.teacher:
        _openSelect('teacher');
        break;
      case FilterType.audience:
        _openSelect('room');
        break;
      case FilterType.personal:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildHeader(),
      body:  Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildFilterBar()),
              SliverToBoxAdapter(child: _buildFilterIndicator()),
              SliverToBoxAdapter(child: _buildSegmentedControl()),
              SliverToBoxAdapter(child: _buildCalendarStrip()),
              if (_weekController.loadState == ScheduleLoadState.error)
                SliverToBoxAdapter(child: _buildErrorState())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  sliver: _view == 'week' ? _buildWeekView() : _buildDayView(),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          if (_weekController.loadState == ScheduleLoadState.loading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_filterController.isPersonal)
            Positioned(
              right: 16,
              bottom: 160,
              child: _buildFAB(),
            ),
        ],
      ),
    );
  }

  AppBar _buildHeader() {
    final theme = Theme.of(context);
    return AppBar(
      title: const Text('Расписание'),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded),
          onPressed: _openCalendar,
          tooltip: 'Выбор даты',
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final items = [
    (FilterType.group, 'Группа', Icons.groups),
    (FilterType.teacher, 'Преподаватель', Icons.person),
    (FilterType.audience, 'Аудитория', Icons.meeting_room),
    (FilterType.personal, 'Личное', Icons.person_outline),
  ];
  
  return ValueListenableBuilder<FilterType>(
    valueListenable: _filterController.currentFilterType,
    builder: (context, selectedType, child) {
      return SizedBox(
        height: 70,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedType == item.$1;
              
              return GestureDetector(
                onTap: () {
                  _filterController.setFilterType(item.$1);
                  if (item.$1 != FilterType.personal) {
                    _syncFiltersToController();
                  }
                },
                child: BaseContainer(
                  shadow: isSelected ? true : false,

                  
                  backgroundColor: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,

                  ),
                 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$3,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.$2,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      );
    }
  );
  }


  Widget _buildFilterIndicator() {
    final theme = Theme.of(context);
    if (!_filterController.isPersonal) {
      return TextButton.icon(
      onPressed: _openSelectForCurrentFilter,
      icon: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
      label: Text(
        _filterIndicator,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
    }

    return const SizedBox();
    
  }

  Future<void> _openSelect(String type) async {
    String? result;
    if (type == 'group') {
      result = await context.push<String?>(
        '/schedule/select-group',
        extra: {'selected': _filterController.selectedGroup.value},
      );
      if (result != null && mounted) {
        _filterController.updateGroup(result);
        _syncFiltersToController();
      }
    } else if (type == 'teacher') {
      result = await context.push<String?>(
        '/schedule/select-teacher',
        extra: {'selected': _filterController.selectedTeacher.value},
      );
      if (result != null && mounted) {
        _filterController.updateTeacher(result);
        _syncFiltersToController();
      }
    } else if (type == 'room') {
      result = await context.push<String?>(
        '/schedule/select-room',
        extra: {'selected': _filterController.selectedAudience.value},
      );
      if (result != null && mounted) {
        _filterController.updateAudience(result);
        _syncFiltersToController();
      }
    }
  }

  Future<void> _openCalendar() async {
    final selected = await context.push<DateTime?>(
      '/schedule/calendar',
      extra: {'initialDate': _weekController.selectedDate},
    );
    if (selected != null && mounted) {
      _weekController.goToWeekContaining(selected);
    }
  }

Widget _buildSegmentedControl() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return
    BaseContainer(
      shadow: false,
      
      margin:const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg).copyWith(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 4),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Анимированный индикатор
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(
                  left: _view == 'today' ? 4 : constraints.maxWidth / 2,
                ),
                width: (constraints.maxWidth - 8) / 2,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // Кнопки
              Row(
                children: [
                  _buildSegmentButton(
                    label: 'Сегодня',
                    value: 'today',
                    isSelected: _view == 'today',
                  ),
                  _buildSegmentButton(
                    label: 'Неделя',
                    value: 'week',
                    isSelected: _view == 'week',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
}

Widget _buildSegmentButton({
  required String label,
  required String value,
  required bool isSelected,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _view = value),
      child: Container(
        height: 35,
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCalendarStrip() {
    final week = _weekController.currentWeek;
    final theme = Theme.of(context);
    final isLoading = _weekController.loadState == ScheduleLoadState.loading;

    if (_view == 'week') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.cardColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: isLoading ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
              ),
              onPressed: isLoading ? null : () => _weekController.goToPreviousWeek(),
            ),
            Text(
              week.formattedPeriod,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleSmall?.color ?? AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: isLoading ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
              ),
              onPressed: isLoading ? null : () => _weekController.goToNextWeek(),
            ),
          ],
        ),
      );
    }

    // Режим "Сегодня": полоска с 7 днями и датами
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        if (d.primaryVelocity! > 0) {
          _weekController.goToPreviousWeek();
        } else {
          _weekController.goToNextWeek();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: theme.cardColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isLoading ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
                  ),
                  onPressed: isLoading ? null : () => _weekController.goToPreviousWeek(),
                ),
                Text(
                  week.formattedPeriod,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleSmall?.color ?? AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isLoading ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
                  ),
                  onPressed: isLoading ? null : () => _weekController.goToNextWeek(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(7, (i) {
                final dayLabel = WeekService.weekDayLabels[i];
                final date = week.dates[i];
                final dayNum = date.day;
                final isSelected = _weekController.selectedDayIndex == i;
                final today = DateTime.now();
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected
                          ? AppColors.primaryLight
                          : isToday
                              ? AppColors.primaryLight.withValues(alpha: 0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _weekController.selectDay(i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                dayLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '$dayNum',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final theme = Theme.of(context);
    final children = <Widget>[];
    final week = _weekController.currentWeek;
    final isPersonal = _filterController.isPersonal;

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final dayOfWeek = dayIndex + 1;
      final date = week.dates[dayIndex];
      final dayLabel = WeekService.weekDayLabels[dayIndex];
      final dayLessons = isPersonal
          ? <Lesson>[]
          : _filteredLessons.where((l) => l.dayOfWeek == dayOfWeek).toList();
      final dayTasks = _tasksForDate(date);

      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            '$dayLabel, ${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
            ),
          ),
        ),
      );

      final merged = <({String time, Widget widget})>[];
      for (final l in dayLessons) {
        merged.add((time: l.timeStart, widget: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LessonCard(
            lesson: l,
            onTap: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _LessonDetailsSheet(lesson: l),
              );
            },
          ),
        )));
      }
      if (isPersonal) {
        for (final t in dayTasks) {
          merged.add((time: t.time, widget: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PersonalTaskCard(
              task: t,
              onDelete: () => _confirmDeleteTask(context, t),
            ),
          )));
        }
      }
      merged.sort((a, b) => a.time.compareTo(b.time));

      for (final m in merged) {
        children.add(m.widget);
      }
      if (merged.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Text(
                isPersonal ? 'Задач нет' : 'Занятий нет',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }
    }
    return SliverList(
      delegate: SliverChildListDelegate(children),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Не удалось загрузить расписание',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _weekController.retryLoad(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final dayOfWeek = _weekController.selectedDayIndex + 1;
    final date = _weekController.currentWeek.dates[_weekController.selectedDayIndex];
    final isPersonal = _filterController.isPersonal;
    final dayLessons = isPersonal
        ? <Lesson>[]
        : _filteredLessons.where((l) => l.dayOfWeek == dayOfWeek).toList();
    final dayTasks = _tasksForDate(date);

    final merged = <({String time, Widget widget})>[];
    for (final l in dayLessons) {
      merged.add((time: l.timeStart, widget: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _LessonCard(
          lesson: l,
          onTap: () {
            showModalBottomSheet(
              useRootNavigator: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _LessonDetailsSheet(lesson: l),
            );
          },
        ),
      )));
    }
    // Личные задачи — только на вкладке «Личное».
    if (isPersonal) {
      for (final t in dayTasks) {
        merged.add((time: t.time, widget: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PersonalTaskCard(
            task: t,
            onDelete: () => _confirmDeleteTask(context, t),
          ),
        )));
      }
    }
    merged.sort((a, b) => a.time.compareTo(b.time));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => merged[index].widget,
        childCount: merged.length,
      ),
    );
  }

  Future<void> _confirmDeleteTask(BuildContext context, PersonalTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('«${task.title}» будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Удалить', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await TaskService.instance.deleteTask(task.id);
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Задача удалена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  Widget _buildFAB() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: _showAddTaskDialog,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final forDate = _view == 'week'
        ? _weekController.currentWeek.startDate
        : _weekController.currentWeek.dates[_weekController.selectedDayIndex];
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        forDate: forDate,
        onSaved: _loadTasks,
      ),
    );
  }
}

class _SimpleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SimpleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Color> _lessonTypeColor(LessonType type) {
  switch (type) {
    case LessonType.lecture:
      return [AppColors.primaryLight,AppColors.hintprimary];
    case LessonType.lab:
      return [AppColors.warning, AppColors.hintwarning];
    case LessonType.retake:
      return [AppColors.error, AppColors.hinterror];
    case LessonType.practice:
      return [const Color.fromARGB(255, 26, 223, 157),AppColors.hintsuccess];
    case LessonType.personal:
      return [AppColors.primaryLight,AppColors.hintprimary];
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _lessonTypeColor(lesson.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[1],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color[0], width: 1.2),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color.fromARGB(255, 233, 233, 233),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${lesson.timeStart} - ${lesson.timeEnd}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    lesson.typeLabel,
                    style: TextStyle(fontSize: 12, color: color[0]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lesson.subject??'', 
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${lesson.teacher} • ${lesson.room}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonDetailsSheet extends StatelessWidget {
  final Lesson lesson;

  const _LessonDetailsSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
          left: BorderSide(color: theme.dividerColor),
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subject?? '',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primaryLight,
            label: 'Время',
            value: '${lesson.timeStart} - ${lesson.timeEnd}',
          ),
          _DetailRow(
            icon: Icons.person_rounded,
            iconColor: AppColors.success,
            label: 'Преподаватель',
            value: lesson.teacher?? '',
            // subtitle: '★ 4.2 (127 отзывов)',
          ),
          _DetailRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: 'Аудитория',
            value: '${lesson.room}, ${lesson.building}',
            // subtitle: '350м • 5 мин пешком',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Expanded(
              //   child: ElevatedButton(
              //     onPressed: () => Navigator.pop(context),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: theme.colorScheme.primary,
              //       foregroundColor: theme.colorScheme.onPrimary,
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //     ),
              //     child: const Text('Построить маршрут'),
              //   ),
              // ),
              const SizedBox(width: 12),
              // Expanded(
              //   child: OutlinedButton(
              //     onPressed: () => Navigator.pop(context),
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: theme.colorScheme.primary,
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //       side: BorderSide(color: theme.dividerColor),
              //     ),
              //     child: const Text('Отметить посещение'),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,

  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                // if (subtitle != null)
                //   Text(
                //     subtitle!,
                //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //       color: Theme.of(context).colorScheme.onSurfaceVariant,
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

