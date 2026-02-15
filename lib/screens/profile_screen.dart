import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../core/services/settings_service.dart';
import '../core/widgets/base_container.dart';
import '../data/mock_data.dart';
import '../data/schedule_mock_data.dart';
import '../models/task.dart';
import '../widgets/app_progress.dart';

/// Профиль (эквивалент Profile.tsx)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _role;
  String? _defaultGroupId;
  String? _defaultTeacherName;
  List<Task> _taskList = MockData.tasks;

  @override
  void initState() {
    super.initState();
    _role = SettingsService.getProfileRole();
    _defaultGroupId = SettingsService.getDefaultGroupId() ?? ScheduleMockData.groupIds.first;
    _defaultTeacherName = SettingsService.getDefaultTeacherId() ?? ScheduleMockData.teacherNames.first;
  }

  void _toggleTask(String id) {
    setState(() {
      _taskList = _taskList
          .map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _taskList.where((t) => t.completed).length;
    final totalTasks = _taskList.length;
    final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildRoleSwitcher(),
                const SizedBox(height: 16),
                _buildStatistics(completionRate),
                const SizedBox(height: 16),
                _buildTasksSection(completedTasks, totalTasks, completionRate),
                const SizedBox(height: 16),
                _buildAchievements(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Иван Петров',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ИУ5-31б',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Активный студент',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    return BaseContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Роль',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _RoleTile(
            role: 'student',
            title: 'Студент',
            subtitle: _defaultGroupId ?? 'МО-231',
            selected: _role == 'student',
            onTap: () async {
              setState(() => _role = 'student');
              await SettingsService.setProfileRole('student');
            },
          ),
          const SizedBox(height: 8),
          _RoleTile(
            role: 'teacher',
            title: 'Преподаватель',
            subtitle: _defaultTeacherName ?? 'Иванов И.И.',
            selected: _role == 'teacher',
            onTap: () async {
              setState(() => _role = 'teacher');
              await SettingsService.setProfileRole('teacher');
            },
          ),
          const SizedBox(height: 16),
          if (_role == 'student') ...[
            const Text('Группа по умолчанию', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _defaultGroupId ?? ScheduleMockData.groupIds.first,
              isExpanded: true,
              items: ScheduleMockData.groupIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _defaultGroupId = v);
                await SettingsService.setDefaultGroupId(v);
              },
            ),
          ],
          if (_role == 'teacher') ...[
            const Text('Преподаватель по умолчанию', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _defaultTeacherName ?? ScheduleMockData.teacherNames.first,
              isExpanded: true,
              items: ScheduleMockData.teacherNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _defaultTeacherName = v);
                await SettingsService.setDefaultTeacherId(v);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(int completionRate) {
    return Row(
      children: [
        const Expanded(
          child: BaseContainer(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Посещаемость', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Icon(Icons.trending_up_rounded, color: AppColors.success, size: 16),
                  ],
                ),
                SizedBox(height: 8),
                Text('78%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                SizedBox(height: 8),
                AppProgress(value: 78, height: 8),
                SizedBox(height: 8),
                Text('За неделю', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Активность', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('4.2', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < 4 ? AppColors.primaryLight : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 8),
                const Text('За месяц', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection(int completedTasks, int totalTasks, int completionRate) {
    return BaseContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Мои задачи',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedTasks/$totalTasks',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppProgress(value: completionRate.toDouble(), height: 8),
          const SizedBox(height: 8),
          Text('$completionRate% выполнено', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
    final achievements = [
      ('🎯', 'Отличник'),
      ('⚡', 'Скорость'),
      ('🔥', 'Серия'),
      ('🏆', 'Чемпион'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.error.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Достижения',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: achievements.map((a) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.$1, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    a.$2,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

class _RoleTile extends StatelessWidget {
  final String role;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryLight : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primaryLight : AppColors.divider,
                    width: 2,
                  ),
                  color: selected ? AppColors.primaryLight : Colors.transparent,
                ),
                child: selected ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white)) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
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
    final isUrgent = task.deadline == 'сегодня' || task.deadline == 'завтра';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: task.completed ? AppColors.success.withValues(alpha: 0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: task.completed ? AppColors.success.withValues(alpha: 0.2) : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: task.completed ? AppColors.success : AppColors.divider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: task.completed ? AppColors.textSecondary : AppColors.primary,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.deadline,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUrgent ? AppColors.error : AppColors.textSecondary,
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
