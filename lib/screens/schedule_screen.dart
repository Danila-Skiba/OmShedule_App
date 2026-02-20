import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../core/services/settings_service.dart';
import '../data/schedule_mock_data.dart';
import '../models/lesson.dart';
import '../models/schedule_type.dart';

const _periodStart = '17 фев';
const _periodEnd = '24 фев';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _view = 'today';
  late ScheduleType _scheduleType;
  String? _selectedGroupId;
  String? _selectedTeacherName;
  String? _selectedRoomId;
  int _selectedDay = 1;
  int _weekOffset = 0;
  Lesson? _selectedLesson;

  final _newEvent = _NewEventForm();

  Set<String> get _selectedGroupIds =>
      _selectedGroupId != null ? {_selectedGroupId!} : {};
  Set<String> get _selectedTeacherNames =>
      _selectedTeacherName != null ? {_selectedTeacherName!} : {};
  Set<String> get _selectedRoomIds =>
      _selectedRoomId != null ? {_selectedRoomId!} : {};

  @override
  void initState() {
    super.initState();
    _applyDefaultsFromProfile();
    _selectedDay = DateTime.now().weekday.clamp(1, 6);
  }

  void _applyDefaultsFromProfile() {
    final role = SettingsService.getProfileRole();
    if (role == 'student') {
      _scheduleType = ScheduleType.group;
      _selectedGroupId = SettingsService.getDefaultGroupId() ?? ScheduleMockData.groupIds.first;
      _selectedTeacherName = null;
      _selectedRoomId = null;
    } else {
      _scheduleType = ScheduleType.teacher;
      _selectedTeacherName = SettingsService.getDefaultTeacherId() ?? ScheduleMockData.teacherNames.first;
      _selectedGroupId = null;
      _selectedRoomId = null;
    }
  }

  List<Lesson> get _filteredLessons {
    return ScheduleMockData.lessonsFiltered(
      groupIds: _selectedGroupIds.isEmpty ? null : _selectedGroupIds,
      teacherNames: _selectedTeacherNames.isEmpty ? null : _selectedTeacherNames,
      roomIds: _selectedRoomIds.isEmpty ? null : _selectedRoomIds,
    );
  }

  String get _filterIndicator {
    if (_selectedGroupId != null) return '$_selectedGroupId';
    if (_selectedTeacherName != null) return '$_selectedTeacherName';
    if (_selectedRoomId != null) return '$_selectedRoomId';
    return 'Выберите группу, преподавателя или аудиторию';
  }

  int get _todayIndex {
    final today = DateTime.now().weekday;
    return today == 7 ? 0 : today - 1;
  }

  static const _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];

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
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                sliver: _view == 'week' ? _buildWeekView() : _buildDayView(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 80,
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
      );
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.all(AppConstants.spacingLg),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (theme.cardColor).withValues(alpha: isDark ? 0.8 : 0.9),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: _FilterChip(
                  label: 'Группа',
                  selected: _selectedGroupId != null,
                  onTap: () => {} //_openSelect('group'),
                ),
              ),
              Expanded(
                child: _FilterChip(
                  label: 'Преподаватель',
                  selected: _selectedTeacherName != null,
                  onTap: () => {} //_openSelect('teacher'),
                ),
              ),
              Expanded(
                child: _FilterChip(
                  label: 'Аудитория',
                  selected: _selectedRoomId != null,
                  onTap: () => {} //_openSelect('room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterIndicator() {
    final theme = Theme.of(context);
    return TextButton.icon(
            onPressed: () => _openSelect('group'),
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

  Future<void> _openSelect(String type) async {
    String? result;
    if (type == 'group') {
      result = await context.push<String?>(
        '/schedule/select-group',
        extra: {'selected': _selectedGroupId},
      );
      if (result != null && mounted) setState(() => _selectedGroupId = result);
    } else if (type == 'teacher') {
      result = await context.push<String?>(
        '/schedule/select-teacher',
        extra: {'selected': _selectedTeacherName},
      );
      if (result != null && mounted) setState(() => _selectedTeacherName = result);
    } else if (type == 'room') {
      result = await context.push<String?>(
        '/schedule/select-room',
        extra: {'selected': _selectedRoomId},
      );
      if (result != null && mounted) setState(() => _selectedRoomId = result);
    }
  }

  Widget _buildSegmentedControl() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      color: theme.cardColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.6 : 0.8),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentChip(
                        label: 'Сегодня',
                        value: 'today',
                        active: _view,
                        onTap: () => setState(() => _view = 'today'),
                      ),
                    ),
                    Expanded(
                      child: _SegmentChip(
                        label: 'Неделя',
                        value: 'week',
                        active: _view,
                        onTap: () => setState(() => _view = 'week'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarStrip() {
    if (_view == 'week') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).cardColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              onPressed: () => setState(() => _weekOffset -= 1),
            ),
            Text(
              '$_periodStart - $_periodEnd',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleSmall?.color ?? AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onPressed: () => setState(() => _weekOffset += 1),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        if (d.primaryVelocity! > 0) {
          setState(() => _selectedDay = (_selectedDay - 1).clamp(1, 6));
        } else {
          setState(() => _selectedDay = (_selectedDay + 1).clamp(1, 6));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _selectedDay = (_selectedDay - 1).clamp(1, 6)),
                ),
                Text(
                  '$_periodStart - $_periodEnd',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleSmall?.color ?? AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _selectedDay = (_selectedDay + 1).clamp(1, 6)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(6, (i) {
                final dayNum = i + 1;
                final isSelected = _selectedDay == dayNum;
                final isToday = dayNum == DateTime.now().weekday;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected
                          ? AppColors.primaryLight
                          : isToday
                              ? AppColors.primaryLight.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = dayNum),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _weekDays[i],
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
    final children = <Widget>[];
    for (var dayIndex = 0; dayIndex < 6; dayIndex++) {
      final dayNum = dayIndex + 1;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            _weekDays[dayIndex],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary,
            ),
          ),
        ),
      );
      final dayLessons = _filteredLessons.where((l) => l.dayOfWeek == dayNum).toList();
      for (final lesson in dayLessons) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LessonCard(
              lesson: lesson,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _LessonDetailsSheet(lesson: lesson),
                );
              },
            ),
          ),
        );
      }
      if (dayLessons.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Text(
                'Занятий нет',
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary),
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

  Widget _buildDayView() {
    final dayNum = _selectedDay;
    final dayLessons = _filteredLessons.where((l) => l.dayOfWeek == dayNum).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LessonCard(
            lesson: dayLessons[index],
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _LessonDetailsSheet(lesson: dayLessons[index]),
              );
            },
          ),
        ),
        childCount: dayLessons.length,
      ),
    );
  }

  Widget _buildFAB() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () => _showAddEventDialog(context),
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    _newEvent.reset();
    showDialog(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: _AddEventDialog(
          form: _newEvent,
          onCancel: () => Navigator.of(ctx).pop(),
          onSave: () {
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = active == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    case LessonType.exam:
      return [AppColors.error, AppColors.hinterror];
    case LessonType.personal:
      return [AppColors.success,AppColors.hintsuccess];
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
              lesson.subject,
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
            lesson.subject,
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
            value: lesson.teacher,
            subtitle: '★ 4.2 (127 отзывов)',
          ),
          _DetailRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: 'Аудитория',
            value: '${lesson.room}, ${lesson.building}',
            subtitle: '350м • 5 мин пешком',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Построить маршрут'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: const Text('Отметить посещение'),
                ),
              ),
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
  final String? subtitle;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
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
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewEventForm {
  String title = '';
  String type = 'personal';
  String time = '';
  String room = '';
  String notes = '';

  void reset() {
    title = '';
    type = 'personal';
    time = '';
    room = '';
    notes = '';
  }
}

class _AddEventDialog extends StatefulWidget {
  final _NewEventForm form;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _AddEventDialog({
    required this.form,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _roomController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.form.title);
    _roomController = TextEditingController(text: widget.form.room);
    _notesController = TextEditingController(text: widget.form.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = [
      (id: 'personal', label: 'Личное', color: AppColors.success),
      (id: 'meeting', label: 'Встреча', color: AppColors.primaryLight),
      (id: 'exam', label: 'Экзамен', color: AppColors.error),
      (id: 'other', label: 'Другое', color: AppColors.warning),
    ];
    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добавить событие',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text('Название', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Встреча, задача, экзамен...',
                ),
                onChanged: (v) => widget.form.title = v,
              ),
              const SizedBox(height: 16),
              Text('Тип', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: types.map((t) => Material(
                  color: widget.form.type == t.id ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => widget.form.type = t.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.form.type == t.id ? theme.colorScheme.primary : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(t.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Время', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(hintText: '--:--'),
                          onChanged: (v) => widget.form.time = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Аудитория', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _roomController,
                          decoration: const InputDecoration(hintText: '312'),
                          onChanged: (v) => widget.form.room = v,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Заметки', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Дополнительная информация...',
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => widget.form.notes = v,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
                    ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Добавить'),
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
