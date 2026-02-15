import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';
import '../core/widgets/base_container.dart';
import '../widgets/app_switch.dart';

/// Настройки (эквивалент Settings.tsx)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _language = 'ru';

  static const _accentOptions = [
    (id: 'blue', name: 'Синий (ОмГТУ)', color: Color(0xFF1E3A8A)),
    (id: 'green', name: 'Зелёный', color: Color(0xFF10B981)),
    (id: 'purple', name: 'Фиолетовый', color: Color(0xFF8B5CF6)),
    (id: 'red', name: 'Красный', color: Color(0xFFEF4444)),
  ];

  static const _languages = [
    (id: 'ru', name: 'Русский', flag: '🇷🇺'),
    (id: 'en', name: 'English', flag: '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAppearanceSection(),
                const SizedBox(height: 16),
                _buildNotificationsSection(),
                const SizedBox(height: 16),
                _buildLanguageSection(),
                const SizedBox(height: 16),
                _buildAccountSection(),
                const SizedBox(height: 24),
                _buildAppInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Настройки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    final themeNotifier = context.watch<ThemeNotifier>();
    final themeMode = themeNotifier.themeMode;
    final accentColor = themeNotifier.accentColor;
    final targetValue = accentColor?.value ?? _accentOptions.first.color.value;
    final selectedAccent = _accentOptions.firstWhere(
      (t) => t.color.value == targetValue,
      orElse: () => _accentOptions.first,
    );

    return BaseContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Внешний вид',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Тема',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode_rounded)),
                    ButtonSegment(value: ThemeMode.system, label: Text('Системная'), icon: Icon(Icons.settings_brightness_rounded)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> s) {
                    themeNotifier.setThemeMode(s.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Акцентный цвет',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: _accentOptions.map((t) {
                    final selected = selectedAccent.id == t.id;
                    return Material(
                      color: selected ? AppColors.primaryLight.withValues(alpha: 0.05) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => themeNotifier.setAccentColor(t.color),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.primaryLight : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: t.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Уведомления',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _NotificationRow(
                  title: 'Push-уведомления',
                  subtitle: 'О парах и событиях',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                _NotificationRow(
                  title: 'Напоминания',
                  subtitle: 'За 15 минут до пары',
                  value: true,
                  onChanged: (_) {},
                ),
                _NotificationRow(
                  title: 'Новости ОмГТУ',
                  subtitle: 'Важные объявления',
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Язык и регион',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _languages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _language == lang.id ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _language = lang.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _language == lang.id ? AppColors.primaryLight : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            lang.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_language == lang.id) ...[
                            const Spacer(),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_rounded,
            iconColor: AppColors.primaryLight,
            title: 'Аккаунт',
            subtitle: 'Управление профилем',
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.lock_rounded,
            iconColor: AppColors.success,
            title: 'Конфиденциальность',
            subtitle: 'Безопасность данных',
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.warning,
            title: 'Помощь и поддержка',
            subtitle: 'FAQ и обратная связь',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return const Center(
      child: Column(
        children: [
          Text(
            AppStrings.appName,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            'Версия ${AppStrings.appVersion}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
