import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/core/services/schedule_news.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/base_container.dart';
import '../models/lesson.dart';
import '../models/news.dart';
import '../widgets/app_progress.dart';
import 'package:cached_network_image/cached_network_image.dart';


// const _host = '172.20.10.8'; //localhost
const _host = 'localhost';

const _monthNames = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _weekDayNames = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

/// Главная страница TODO: подтягивание текущего расписания с помощью API или кеширования
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = NewsRepositoryImpl();
  List<News> _news = [];
  String? _error;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mon .. 7=Sun, в mock ПН=1
    // final todayLessons = ApiClient.instance.lessons.where((l) => l.dayOfWeek == today).toList();
    // final completedTasks = MockData.tasks.where((t) => t.completed).length;
    // final totalTasks = MockData.tasks.length;
    // final nextLesson = todayLessons.isNotEmpty ? todayLessons.first : null;
    // const minutesToNext = 14;

    final theme = Theme.of(context);




    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body:  CustomScrollView(
        slivers: [
              SliverList(
              delegate: SliverChildListDelegate([
                // _buildQuickActions(context, nextLesson),
                const SizedBox(height: 16),
                // _buildStatsRow(completedTasks, totalTasks, minutesToNext),
                const SizedBox(height: 16),
                // _buildScheduleSection(context, todayLessons),
                const SizedBox(height: 16),
                _buildNewsSection(_news),
                const SizedBox(height: 100)
              ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _loadData() async {

    setState(() {
      _isLoading = true;
    });
    
    final result = await _repository.getNews();

    setState(() {
      if (result.error != null){
        _error = result.error;
        _news = [];
      } else {
        _error = null;
        _news = result.news;
      }
    });

  }

  

  AppBar _buildAppBar(BuildContext context) {
    // final theme = Theme.of(context);
    return AppBar(
        title: const Text('Расписание ОмГТУ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showAppBarPopup(context),
          ),
        ],
      );
  }

  void _showAppBarPopup(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.cardDark : Colors.white).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PopupTile(
                    icon: Icons.settings_rounded,
                    label: 'Настройки',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/settings');
                    },
                  ),
                  // Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.6)),
                  // _PopupTile(
                  //   icon: Icons.notifications_rounded,
                  //   label: 'Уведомления',
                  //   onTap: () {
                  //     Navigator.of(ctx).pop();
                  //   },
                  // ),
                  // Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.6)),
                  // _PopupTile(
                  //   icon: Icons.logout_rounded,
                  //   label: 'Выйти',
                  //   onTap: () {
                  //     Navigator.of(ctx).pop();
                  //     _logout(context);
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
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
    return Padding(
      padding: const EdgeInsetsGeometry.all(16),
      child: Row(
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * 0.5,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context, List<Lesson> todayLessons) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthNames[now.month - 1]}, ${_weekDayNames[now.weekday - 1]}';
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 16), 
      child: BaseContainer(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Расписание на сегодня',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: todayLessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ScheduleRow(
                  lesson: todayLessons[index],
                  index: index,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go('/schedule'),
              icon: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
              label: Text(
                'Показать всё расписание',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildNewsSection(List<News> news) {

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 18, bottom: 12),
        child: Text(
          'Новости ОмГТУ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      Container(
        height: 410,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: news.length,
          itemBuilder: (context, index) => SizedBox(
            width: 300, 
            child: _NewsCard(news: news[index]),
          ),
          separatorBuilder: (context, index) => const SizedBox(width: 12),
        ),
      ),
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
  
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }

}

class _PopupTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PopupTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.spacingMd),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                  lesson.subject?? '',
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

  static const double _imageHeight = 180;
  static const double _titleHeight = 54; // фиксируем место под 3 строки заголовка

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      margin: const EdgeInsets.only(left: 16, bottom: 24, top: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя часть с датой и иконкой
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  news.date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Заголовок: фиксированная высота, чтобы изображение не прыгало
          SizedBox(
            height: _titleHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                news.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 12),
                    // Изображение: фиксированный блок + аккуратное оформление
          Container(
            width: double.infinity,
            height: _imageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'http://${_host}:8000/api/news/images/${news.id}',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => Container(
                      color: AppColors.primaryLight.withOpacity(0.06),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primaryLight.withOpacity(0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Не удалось загрузить изображение',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Лёгкий градиент для глубины
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(news.url)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                // backgroundColor: AppColors.primaryLight.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Читать дальше',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}