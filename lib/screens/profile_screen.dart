
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../core/services/task_service.dart';
import '../widgets/base_container.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import '../models/personal_task.dart';
import '../widgets/app_progress.dart';
import '../widgets/personal_task_card.dart';
import 'add_task_screen.dart';

/// Профиль
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  void _editTask(PersonalTask task) {
    final dateParts = task.date.split('-');
    final forDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          forDate: forDate,
          onSaved: _loadTasks,
          existingTask: task,
        ),
      ),
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
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // SliverToBoxAdapter(
          //   child: Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.all(24),
          //     child: Row(
          //       children: [
          //         CircleAvatar(
          //           radius: 40,
          //           backgroundColor: theme.colorScheme.primaryContainer,
          //           child: Icon(
          //             Icons.person_rounded,
          //             size: 40,
          //             color: theme.colorScheme.onPrimaryContainer,
          //           ),
          //         ),
          //         const SizedBox(width: 16),
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text(
          //                 'Иван Петров',
          //                 style: theme.textTheme.titleLarge?.copyWith(
          //                   fontWeight: FontWeight.bold,
          //                   color: theme.colorScheme.onSurface,
          //                 ),
          //               ),
          //               const SizedBox(height: 4),
          //               Text(
          //                 'ИУ5-31б',
          //                 style: theme.textTheme.bodyMedium?.copyWith(
          //                   color: theme.colorScheme.onSurfaceVariant,
          //                 ),
          //               ),
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.emoji_events_rounded, size: 16, color: theme.colorScheme.tertiary),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Активный студент',
          //                     style: theme.textTheme.bodySmall?.copyWith(
          //                       fontWeight: FontWeight.w600,
          //                       color: theme.colorScheme.onSurfaceVariant,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatistics(completionRate),
                const SizedBox(height: 16),
                _buildTasksSection(completedTasks, totalTasks, completionRate),
                const SizedBox(height: 16),
                // _buildAchievements(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(int completionRate) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurf = theme.colorScheme.onSurface;
    final onSurfVar = theme.colorScheme.onSurfaceVariant;
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: BaseContainer(
            isGlass: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Посещаемость', style: theme.textTheme.bodyMedium?.copyWith(color: onSurfVar)),
                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text('78%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 8),
                const AppProgress(value: 78, height: 8),
                const SizedBox(height: 8),
                Text('За неделю', style: theme.textTheme.bodySmall?.copyWith(color: onSurfVar)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BaseContainer(
            isGlass: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Активность', style: theme.textTheme.bodyMedium?.copyWith(color: onSurfVar)),
                    Icon(Icons.calendar_today_rounded, color: theme.colorScheme.secondary, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text('4.2', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < 4 ? theme.colorScheme.primary : theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 8),
                Text('За месяц', style: theme.textTheme.bodySmall?.copyWith(color: onSurfVar)),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildAchievements() {
    final theme = Theme.of(context);
    final achievements = [
      ('🎯', 'Отличник'),
      ('⚡', 'Скорость'),
      ('🔥', 'Серия'),
      ('🏆', 'Чемпион'),
      ('🏆', 'Чемпион')
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.error.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Достижения',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: achievements.map((a) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.$1, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    a.$2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

