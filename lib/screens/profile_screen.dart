
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../core/services/task_service.dart';
import '../core/services/auth_service.dart';
import '../core/utils/platform_utils.dart';
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
        title: 'Профиль',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAuthCard(theme)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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

  Widget _buildAuthCard(ThemeData theme) {
    final auth = context.watch<AuthService>();
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: BaseContainer(
        isGlass: isDark,
        padding: const EdgeInsets.all(16),
        child: auth.isAuthenticated
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primary.withValues(alpha: 0.12),
                    child: Text(
                      (auth.user?.name ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'Пользователь',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () async {
                        final confirmed = await AppDialog.show(
                          context: context,
                          icon: Icons.logout_rounded,
                          title: 'Выйти из аккаунта?',
                          confirmText: 'Выйти',
                          isDestructive: true,
                        );
                        if (confirmed == true && mounted) {
                          await AuthService.instance.logout();
                          if (mounted) AppSnackBar.success(context, 'Вы вышли из аккаунта');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primary.withValues(alpha: 0.08),
                    child: Icon(Icons.person_outline_rounded, size: 24, color: primary.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вы не авторизованы',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Войдите для доступа к конспектам',
                          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox( // iOS
                    height: 38,
                    child: isIOS
                        ? CupertinoButton(
                            onPressed: () => context.push('/auth'),
                            color: primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            borderRadius: BorderRadius.circular(10),
                            minSize: 38,
                            child: const Text('Войти', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                          )
                        : ElevatedButton(
                            onPressed: () => context.push('/auth'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: const Text('Войти', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                  ),
                ],
              ),
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

