import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../core/widgets/base_container.dart';
import '../data/mock_data.dart';
import '../models/task.dart';
import '../widgets/app_progress.dart';

/// Профиль
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Task> _taskList = MockData.tasks;

  void _toggleTask(String id) {
    setState(() {
      _taskList = _taskList
          .map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t)
          .toList();
    });
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
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Иван Петров',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ИУ5-31б',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, size: 16, color: theme.colorScheme.tertiary),
                            const SizedBox(width: 8),
                            Text(
                              'Активный студент',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatistics(completionRate),
                const SizedBox(height: 16),
                _buildTasksSection(completedTasks, totalTasks, completionRate),
                const SizedBox(height: 16),
                // _buildAchievements(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(int completionRate) {
    final theme = Theme.of(context);
    final onSurf = theme.colorScheme.onSurface;
    final onSurfVar = theme.colorScheme.onSurfaceVariant;
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: BaseContainer(
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
    return BaseContainer(
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
          ..._taskList.map((task) => _TaskTile(
            task: task,
            onTap: () => _toggleTask(task.id),
          )),
        ],
      ),
    );
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

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = task.deadline == 'сегодня' || task.deadline == 'завтра';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: task.completed
            ? AppColors.success.withValues(alpha: 0.1)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: task.completed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : theme.dividerColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: task.completed ? AppColors.success : theme.dividerColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: task.completed
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.deadline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isUrgent ? AppColors.error : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
