import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/services/task_service.dart';
import '../core/utils/platform_utils.dart';
import '../widgets/base_container.dart';
import '../widgets/app_dialog.dart';
import '../models/personal_task.dart';
import '../ui/adaptive/adaptive_exports.dart';
import '../widgets/app_progress.dart';
import '../widgets/personal_task_card.dart';
import 'add_task_screen.dart';

/// Строка списка: либо заголовок дня, либо сама задача.
///
/// Список плоский, чтобы строиться лениво (`SliverList.builder`): задач у
/// пользователя может накопиться сколько угодно, а вкладка показывает их все.
sealed class _TaskRow {
  const _TaskRow();
}

class _DayHeaderRow extends _TaskRow {
  const _DayHeaderRow({
    required this.date,
    required this.total,
    required this.done,
  });

  final DateTime date;
  final int total;
  final int done;
}

class _TaskItemRow extends _TaskRow {
  const _TaskItemRow(this.task);

  final PersonalTask task;
}

/// Задачи пользователя: со вчерашнего дня и все будущие.
///
/// Вчерашний день оставлен намеренно — вчерашняя невыполненная задача не
/// должна исчезать из виду в полночь.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<PersonalTask> _taskList = [];
  List<_TaskRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    TaskService.instance.addListener(_onTasksChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    TaskService.instance.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() => _loadTasks();

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.instance.getTasksFrom(
      _today.subtract(const Duration(days: 1)),
    );
    if (!mounted) return;
    setState(() {
      _taskList = tasks;
      _rows = _buildRows(tasks);
    });
  }

  /// Раскладывает задачи по дням и разворачивает в плоский список строк.
  static List<_TaskRow> _buildRows(List<PersonalTask> tasks) {
    final byDate = <String, List<PersonalTask>>{};
    for (final task in tasks) {
      byDate.putIfAbsent(task.date, () => []).add(task);
    }

    final rows = <_TaskRow>[];
    final dates = byDate.keys.toList()..sort();
    for (final date in dates) {
      final dayTasks = byDate[date]!..sort((a, b) => a.time.compareTo(b.time));
      final parsed = DateTime.tryParse(date);
      if (parsed == null) continue;

      rows.add(_DayHeaderRow(
        date: parsed,
        total: dayTasks.length,
        done: dayTasks.where((t) => t.completed).length,
      ));
      rows.addAll(dayTasks.map(_TaskItemRow.new));
    }
    return rows;
  }

  // Перечитывать список после каждой правки вручную не нужно: `TaskService`
  // уведомляет слушателей сам, а на него подписан `initState`.
  Future<void> _toggleTask(String id) =>
      TaskService.instance.toggleCompleted(id);

  Future<void> _confirmDeleteTask(PersonalTask task) async {
    final confirmed = await AppDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'Удалить задачу?',
      message: '«${task.title}» будет удалена.',
      confirmText: 'Удалить',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      try {
        await TaskService.instance.deleteTask(task.id);
        if (mounted) {
          AppSnackBar.success(context, 'Задача удалена');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, 'Ошибка удаления: $e');
        }
      }
    }
  }

  void _addTask() {
    Navigator.of(context).push(
      buildRoute(AddTaskScreen( // iOS
        forDate: DateTime.now(),
        onSaved: _loadTasks,
      )),
    );
  }

  void _editTask(PersonalTask task) {
    final forDate = DateTime.tryParse(task.date) ?? DateTime.now();
    Navigator.of(context).push(
      buildRoute(AddTaskScreen( // iOS
        forDate: forDate,
        onSaved: _loadTasks,
        existingTask: task,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: 'Задачи',
        useNativeToolbar: true,
        actions: [
          AppAppBarAction(
            iosSymbol: AppIcons.add.symbol,
            icon: AppIcons.add.icon,
            onPressed: _addTask,
          ),
          AppAppBarAction(
            iosSymbol: AppIcons.settings.symbol,
            icon: AppIcons.settings.icon,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            sliver: SliverToBoxAdapter(child: _buildSummary()),
          ),
          if (_rows.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: _rows.length,
                itemBuilder: (context, index) => switch (_rows[index]) {
                  final _DayHeaderRow row => _DayHeader(
                      date: row.date,
                      total: row.total,
                      done: row.done,
                    ),
                  final _TaskItemRow row => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PersonalTaskCard(
                        task: row.task,
                        onTap: () => _editTask(row.task),
                        showCompletedToggle: true,
                        onToggleCompleted: () => _toggleTask(row.task.id),
                        onDelete: () => _confirmDeleteTask(row.task),
                      ),
                    ),
                },
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ),
        ],
      ),
    );
  }

  /// Сводка по всем показанным задачам.
  Widget _buildSummary() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = _taskList.length;
    final done = _taskList.where((t) => t.completed).length;
    final rate = total > 0 ? ((done / total) * 100).round() : 0;

    return BaseContainer(
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.checklist_rounded,
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
                      'Мои задачи',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'Ничего не запланировано'
                          : 'Выполнено $done из $total',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$rate%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            AppProgress(value: rate.toDouble(), height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 12),
            Text(
              'Задач пока нет',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Добавьте первую кнопкой + сверху',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок дня: «Вчера» / «Сегодня» / «Завтра», дальше — дата с днём недели.
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.total,
    required this.done,
  });

  final DateTime date;
  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;

    final isToday = diff == 0;
    final isPast = diff < 0;
    // Прошедший день с незакрытыми задачами — единственное, что здесь стоит
    // выделять цветом: остальное пользователь ещё успеет сделать.
    final overdue = isPast && done < total;

    final label = switch (diff) {
      -1 => 'Вчера',
      0 => 'Сегодня',
      1 => 'Завтра',
      _ => _capitalize(DateFormat('EEEE, d MMMM', 'ru').format(date)),
    };

    final Color accent;
    if (overdue) {
      accent = theme.colorScheme.error;
    } else if (isToday) {
      accent = theme.colorScheme.primary;
    } else {
      accent = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
