import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../core/services/settings_service.dart';
import '../data/schedule_mock_data.dart';
import '../models/lesson.dart';
import '../models/schedule_type.dart';
import 'filter_screen.dart';

/// Период: 17–24 февраля
const _periodStart = '17 фев';
const _periodEnd = '24 фев';

/// Расписание (эквивалент Schedule.tsx)
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _view = 'today'; // today | week
  late ScheduleType _scheduleType;
  Set<String> _selectedGroupIds = {};
  Set<String> _selectedTeacherNames = {};
  Set<String> _selectedRoomIds = {};
  String _searchQuery = '';
  bool _showSearch = false;
  int _selectedDay = 1;
  int _weekOffset = 0;
  Lesson? _selectedLesson;

  final _newEvent = _NewEventForm();

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
      final g = SettingsService.getDefaultGroupId() ?? ScheduleMockData.groupIds.first;
      _selectedGroupIds = {g};
      _selectedTeacherNames = {};
      _selectedRoomIds = {};
    } else {
      _scheduleType = ScheduleType.teacher;
      final t = SettingsService.getDefaultTeacherId() ?? ScheduleMockData.teacherNames.first;
      _selectedTeacherNames = {t};
      _selectedGroupIds = {};
      _selectedRoomIds = {};
    }
  }

  FilterResult get _currentFilterResult => FilterResult(
    selectedGroupIds: _selectedGroupIds,
    selectedTeacherNames: _selectedTeacherNames,
    selectedRoomIds: _selectedRoomIds,
  );

  List<Lesson> get _filteredLessons {
    List<Lesson> list = ScheduleMockData.lessonsFiltered(
      groupIds: _selectedGroupIds.isEmpty ? null : _selectedGroupIds,
      teacherNames: _selectedTeacherNames.isEmpty ? null : _selectedTeacherNames,
      roomIds: _selectedRoomIds.isEmpty ? null : _selectedRoomIds,
    );
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((l) {
      return l.subject.toLowerCase().contains(q) ||
          l.teacher.toLowerCase().contains(q) ||
          l.room.toLowerCase().contains(q);
    }).toList();
  }

  int get _todayIndex {
    final today = DateTime.now().weekday;
    return today == 7 ? 0 : today - 1;
  }

  static const _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSegmentedControl()),
              SliverToBoxAdapter(child: _buildCalendarStrip()),
              SliverPadding(
                padding: const EdgeInsets.all(16),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Расписание',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                          onPressed: _openFilterScreen,
                        ),
                        IconButton(
                          icon: Icon(
                            _showSearch ? Icons.close_rounded : Icons.search_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showSearch = !_showSearch),
                        ),
                      ],
                    ),
                  ],
                ),
            if (_showSearch) ...[
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск по предмету, преподавателю, аудитории...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterScreen() async {
    final result = await context.push<FilterResult?>(
      '/schedule/filter',
      extra: _currentFilterResult,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedGroupIds = result.selectedGroupIds;
        _selectedTeacherNames = result.selectedTeacherNames;
        _selectedRoomIds = result.selectedRoomIds;
      });
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _SegmentChip(label: 'Сегодня', value: 'today', active: _view, onTap: () => setState(() => _view = 'today')),
            _SegmentChip(label: 'Неделя', value: 'week', active: _view, onTap: () => setState(() => _view = 'week')),
          ],
        ),
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
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () => _showAddEventDialog(context),
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    _newEvent.reset();
    showDialog(
      context: context,
      builder: (ctx) => _AddEventDialog(
        form: _newEvent,
        onCancel: () => Navigator.of(ctx).pop(),
        onSave: () {
          // TODO: save event
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final VoidCallback onTap;

  const _SegmentChip({required this.label, required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = active == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
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
   List<Color> color = _lessonTypeColor(lesson.type);
    return 
      // borderRadius: BorderRadius.circular(16),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color[1],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color[0], width: 1.2),
            boxShadow: const [BoxShadow(color: Color.fromARGB(255, 233, 233, 233), blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${lesson.timeStart} - ${lesson.timeEnd}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${lesson.teacher} • ${lesson.room}',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.75)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subject,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
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
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.border),
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
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
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
    final types = [
      (id: 'personal', label: 'Личное', color: AppColors.success),
      (id: 'meeting', label: 'Встреча', color: AppColors.primaryLight),
      (id: 'exam', label: 'Экзамен', color: AppColors.error),
      (id: 'other', label: 'Другое', color: AppColors.warning),
    ];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить событие',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Название', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Встреча, задача, экзамен...',
                ),
                onChanged: (v) => widget.form.title = v,
              ),
              const SizedBox(height: 16),
              const Text('Тип', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: types.map((t) => Material(
                  color: widget.form.type == t.id ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => widget.form.type = t.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.form.type == t.id ? AppColors.primaryLight : AppColors.border,
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
                          Text(t.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                        const Text('Время', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                        const Text('Аудитория', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
              const Text('Заметки', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
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
