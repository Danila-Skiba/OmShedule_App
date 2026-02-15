import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../core/widgets/base_container.dart';
import '../data/mock_data.dart';
import '../models/lesson.dart';
import '../models/news.dart';
import '../widgets/app_progress.dart';

/// Главная страница 
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mon .. 7=Sun, в mock ПН=1
    final todayLessons = MockData.lessons.where((l) => l.dayOfWeek == today).toList();
    final completedTasks = MockData.tasks.where((t) => t.completed).length;
    final totalTasks = MockData.tasks.length;
    final nextLesson = todayLessons.isNotEmpty ? todayLessons.first : null;
    const minutesToNext = 14;

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildAppBar(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // _buildQuickActions(context, nextLesson),
                const SizedBox(height: 16),
                _buildStatsRow(completedTasks, totalTasks, minutesToNext),
                const SizedBox(height: 16),
                _buildScheduleSection(context, todayLessons),
                const SizedBox(height: 16),
                _buildNewsSection(),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                const Text(
                  'Расписание ОмГТУ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                  onPressed: () => _showAppBarMenu(context),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppBarMenu(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const menuWidth = 200.0;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        size.width - menuWidth - 16,
        56 + MediaQuery.paddingOf(context).top,
        size.width - 16,
        56 + MediaQuery.paddingOf(context).top + 1,
      ),
      items: [
        PopupMenuItem(
          onTap: () => _logout(context),
          child: const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          onTap: () => Future.microtask(() => context.push('/settings')),
          child: const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    // TODO: очистка сессии при наличии API
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выход выполнен')),
      );
    }
  }

  Widget _buildQuickActions(BuildContext context, Lesson? nextLesson) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 4;
        const spacing = 8.0;
        const totalSpacing = spacing * (count - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / count;
        final itemHeight = itemWidth / 0.85;
        return SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.primaryLight,
                  title: 'Сегодня',
                  subtitle: nextLesson?.timeStart ?? '08:30',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.groups_rounded,
                  iconColor: AppColors.success,
                  title: 'Группа',
                  subtitle: 'ИУ5-31б',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.warning,
                  title: 'Препод.',
                  subtitle: 'Петров В.В.',
                  onTap: () => context.go('/schedule'),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  title: 'Карты',
                  subtitle: '🗺️',
                  onTap: () => context.go('/maps'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(int completedTasks, int totalTasks, int minutesToNext) {
    return Row(
      children: [
        const Expanded(
          child: BaseContainer(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Посещено пар', style: _subtitleStyle),
                SizedBox(height: 4),
                Text('14/18', style: _boldPrimaryStyle),
                SizedBox(height: 8),
                AppProgress(value: 77.8, height: 4),
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
                const Text('Задачи', style: _subtitleStyle),
                const SizedBox(height: 4),
                Text('$completedTasks/$totalTasks', style: _boldSuccessStyle),
                const SizedBox(height: 8),
                AppProgress(value: totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0, height: 4),
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
                const Text('До следующей', style: _subtitleStyle),
                const SizedBox(height: 4),
                Text('$minutesToNextм', style: _boldWarningStyle),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context, List<Lesson> todayLessons) {
    return BaseContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Расписание на сегодня',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...todayLessons.take(3).toList().asMap().entries.map(
                (e) => _ScheduleRow(lesson: e.value, index: e.key),
              ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.go('/schedule'),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryLight),
            label: const Text(
              'Показать всё расписание',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Новости ОмГТУ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...MockData.news.map((item) => _NewsCard(news: item)),
      ],
    );
  }

  static const TextStyle _subtitleStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const TextStyle _boldPrimaryStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static const TextStyle _boldSuccessStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );
  static const TextStyle _boldWarningStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.warning,
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final Lesson lesson;
  final int index;

  const _ScheduleRow({required this.lesson, this.index = 0});

  @override
  Widget build(BuildContext context) {
    Color dotColor = AppColors.success;
    if (index == 0) dotColor = AppColors.error;
    if (index == 1) dotColor = AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                lesson.timeStart,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.timeEnd,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              height: 1,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

class _NewsCard extends StatelessWidget {
  final News news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.date,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  news.preview,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Читать дальше',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
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
