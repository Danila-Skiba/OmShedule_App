import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/services/task_service.dart';
import '../core/utils/platform_utils.dart';
import '../widgets/base_container.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import '../models/personal_task.dart';
import '../widgets/app_progress.dart';
import '../widgets/personal_task_card.dart';
import 'add_task_screen.dart';

/// Задачи пользователя — личные задачи на сегодня и завтра.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<PersonalTask> _taskList = [];

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

  Future<void> _loadTasks() async {
    final tasks = await TaskService.instance.getTodayAndTomorrowTasks();
    if (mounted) setState(() => _taskList = tasks);
  }

  Future<void> _toggleTask(String id) async {
    await TaskService.instance.toggleCompleted(id);
    _loadTasks();
  }

  Future<void> _confirmDeleteTask(BuildContext context, PersonalTask task) async {
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
        await _loadTasks();
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
    final dateParts = task.date.split('-');
    final forDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
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
    final theme = Theme.of(context);
    final completedTasks = _taskList.where((t) => t.completed).length;
    final totalTasks = _taskList.length;
    final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: buildAppBar( // iOS
        context: context,
        title: 'Задачи',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addTask,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTasksSection(completedTasks, totalTasks, completionRate),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(int completedTasks, int totalTasks, int completionRate) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = _groupTasksByDate(_taskList);

    return BaseContainer(
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Мои задачи',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedTasks/$totalTasks',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppProgress(value: completionRate.toDouble(), height: 8),
          const SizedBox(height: 8),
          Text(
            '$completionRate% выполнено',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (_taskList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Задач пока нет',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...grouped.entries.expand((e) => [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  _formatDateLabel(e.key),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ...e.value.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PersonalTaskCard(
                  task: task,
                  onTap: () => _editTask(task),
                  showCompletedToggle: true,
                  onToggleCompleted: () => _toggleTask(task.id),
                  onDelete: () => _confirmDeleteTask(context, task),
                ),
              )),
            ]),
        ],
      ),
    );
  }

  Map<String, List<PersonalTask>> _groupTasksByDate(List<PersonalTask> tasks) {
    final map = <String, List<PersonalTask>>{};
    for (final t in tasks) {
      map.putIfAbsent(t.date, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    return map;
  }

  String _formatDateLabel(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (d == today) return 'Сегодня';
    if (d == tomorrow) return 'Завтра';
    return DateFormat('d MMM', 'ru').format(d);
  }
}
