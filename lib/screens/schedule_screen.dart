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
import '../widgets/personal_task_card.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _view = 'today';
  late ScheduleType _scheduleType;
  late ScheduleWeekController _weekController;
  late FilterController _filterController;
  List<PersonalTask> _tasks = [];

  ScheduleType get currentScheduleType {
  final filterType = _filterController.currentFilterType.value;
  if (filterType == FilterType.group) return ScheduleType.group;
  if (filterType == FilterType.teacher) return ScheduleType.teacher;
  if (filterType == FilterType.audience) return ScheduleType.audience;
  return ScheduleType.group;
}

  @override
  void initState() {
    super.initState();
    _filterController = FilterController();
    _restoreOrApplyDefaults();
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

  void _onFilterChanged() {
    _saveFilterState();
    setState(() {});
  }

  void _saveFilterState() {
    final ft = _filterController.currentFilterType.value;
    String typeStr;
    switch (ft) {
      case FilterType.group: typeStr = 'group'; break;
      case FilterType.teacher: typeStr = 'teacher'; break;
      case FilterType.audience: typeStr = 'audience'; break;
      case FilterType.personal: typeStr = 'personal'; break;
    }
    SettingsService.setSavedFilterType(typeStr);
    SettingsService.setSavedGroupName(_filterController.selectedGroup.value);
    SettingsService.setSavedTeacherName(_filterController.selectedTeacher.value);
    SettingsService.setSavedAudienceName(_filterController.selectedAudience.value);
  }

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

  void _restoreOrApplyDefaults() {
    final savedType = SettingsService.getSavedFilterType();
    if (savedType != null) {
      // Restore previously selected filter
      _filterController.updateGroup(SettingsService.getSavedGroupName());
      _filterController.updateTeacher(SettingsService.getSavedTeacherName());
      _filterController.updateAudience(SettingsService.getSavedAudienceName());
      FilterType ft;
      switch (savedType) {
        case 'teacher': ft = FilterType.teacher; break;
        case 'audience': ft = FilterType.audience; break;
        case 'personal': ft = FilterType.personal; break;
        default: ft = FilterType.group;
      }
      _scheduleType = ft == FilterType.teacher
          ? ScheduleType.teacher
          : ft == FilterType.audience
              ? ScheduleType.audience
              : ScheduleType.group;
      _filterController.setFilterType(ft);
    } else {
      _applyDefaultsFromProfile();
    }
  }

  void _applyDefaultsFromProfile() {
    final role = SettingsService.getProfileRole();
    if (role == 'student') {
      _scheduleType = ScheduleType.group;
      _filterController.updateGroup(ScheduleData.getgroups.keys.first);
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

  void _goToNextDay() {
    final idx = _weekController.selectedDayIndex;
    if (idx < 6) {
      _weekController.selectDay(idx + 1);
    } else {
      _weekController.goToNextWeek();
    }
  }

  void _goToPreviousDay() {
    final idx = _weekController.selectedDayIndex;
    if (idx > 0) {
      _weekController.selectDay(idx - 1);
    } else {
      _weekController.goToPreviousWeek();
      _weekController.selectDay(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = _filterController.isPersonal;
    final isError = _weekController.loadState == ScheduleLoadState.error;
    final isToday = _view == 'today';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildHeader(),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: isToday
                ? (d) {
                    if (d.primaryVelocity == null) return;
                    if (d.primaryVelocity! > 200) {
                      _goToPreviousDay();
                    } else if (d.primaryVelocity! < -200) {
                      _goToNextDay();
                    }
                  }
                : null,
            child: CustomScrollView(
            slivers: [
              // Scrolls away on scroll-down
              SliverToBoxAdapter(child: _buildFilterBar()),
              SliverToBoxAdapter(child: _buildFilterIndicator()),
              // In "today" mode — pin the segmented control + day strip.
              // In "week" mode — regular sliver (scrolls away with content).
              if (isToday)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyControlsDelegate(
                    extent: 215,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentedControl(),
                        _buildCalendarStrip(),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildSegmentedControl()),
                SliverToBoxAdapter(child: _buildCalendarStrip()),
              ],
              if (isError && !isPersonal)
                SliverToBoxAdapter(child: _buildErrorState())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  sliver: _view == 'week' ? _buildWeekView() : _buildDayView(),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
            ),
          ),
          if (_weekController.loadState == ScheduleLoadState.loading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (isPersonal)
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
            type: currentScheduleType
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
          type:currentScheduleType
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

    if (merged.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              isPersonal ? 'Задач нет' : 'Занятий нет',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
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
    context.push('/schedule/add-task', extra: {'forDate': forDate});
  }
}

class _StickyControlsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const _StickyControlsDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyControlsDelegate old) =>
      old.extent != extent || old.child != child;
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
  final ScheduleType type; // group, teacher, audience

  const _LessonCard({
    required this.lesson,
    required this.onTap,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _lessonTypeColor(lesson.type);
    final hasSubgroup = lesson.subgroup != null && lesson.subgroup!.isNotEmpty;

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
            // Время + тип + подгруппа
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
                if (hasSubgroup) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color[0].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color[0].withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Подгр. ${lesson.subgroup![lesson.subgroup!.length - 1]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color[0],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // Название предмета
            Text(
              lesson.subject ?? '',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Преподаватель и/или Аудитория
            Row(
              children: [
                // Показываем преподавателя, если это НЕ расписание преподавателя
                if (type != ScheduleType.teacher && lesson.teacher?.isNotEmpty == true) ...[
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson.teacher!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (type != ScheduleType.group) ...[
                  Icon(
                    Icons.group_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson.group ?? lesson.subgroup ?? lesson.stream ?? '', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Показываем аудиторию, если это НЕ расписание аудитории
                if (type != ScheduleType.audience && lesson.room?.isNotEmpty == true) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson.room!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
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
          _DetailRow(icon: Icons.group_rounded, iconColor: AppColors.primaryLight, label: 'Группа', value: lesson.group?? lesson.subgroup?? lesson.stream?? ''),
          _DetailRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: 'Аудитория',
            value: '${lesson.room}, ${lesson.building}',
            // subtitle: '350м • 5 мин пешком',
          ),
          
          const SizedBox(height: 24),
          const Row(
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
              SizedBox(width: 12),
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

