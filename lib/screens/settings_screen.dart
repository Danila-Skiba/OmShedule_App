import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';
import '../widgets/base_container.dart';
import '../widgets/app_switch.dart';

/// Настройки 
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _language = 'ru';

  static const _accentOptions = [
    (id: 'blue', color: Color(0xFF8BB5F8)),
    (id: 'green', color: Color(0xFF8EDCBC)),
    (id: 'purple', color: Color(0xFFBBA8F5)),
    (id: 'rose', color: Color(0xFFF5B8D4)),
    (id: 'peach', color: Color(0xFFF5CC97)),
    (id: 'sky', color: Color(0xFF96D9F7)),
  ];

  static const _languages = [
    (id: 'ru', name: 'Русский', flag: '🇷🇺'),
    (id: 'en', name: 'English', flag: '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar:  AppBar(
      title: const Text('Настройки'),    
    ),

    body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAppearanceSection(),
                // const SizedBox(height: 16),
                // _buildNotificationsSection(),
                // const SizedBox(height: 16),
                // _buildLanguageSection(),
                // const SizedBox(height: 16),
                // _buildAccountSection(),
                const SizedBox(height: 24),
                _buildAppInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    final themeNotifier = context.watch<ThemeNotifier>();
    final themeMode = themeNotifier.themeMode;
    final accentColor = themeNotifier.accentColor;
    final targetValue = accentColor?.toARGB32() ?? _accentOptions.first.color.toARGB32();
    final selectedAccent = _accentOptions.firstWhere(
      (t) => t.color.toARGB32() == targetValue,
      orElse: () => _accentOptions.first,
    );

    final theme = Theme.of(context);
    return BaseContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Внешний вид',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Тема',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode_rounded)),
                  ],
                  selected: {themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
                  onSelectionChanged: (Set<ThemeMode> s) {
                    themeNotifier.setThemeMode(s.first);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Акцентный цвет',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _accentOptions.map((t) {
                    final selected = selectedAccent.id == t.id;
                    return GestureDetector(
                      onTap: () => themeNotifier.setAccentColor(t.color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: t.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: t.color.withValues(alpha: 0.3),
                              blurRadius: selected ? 10 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                            : null,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Уведомления',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Язык и регион',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _languages.map((lang) {
                final selected = _language == lang.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _language = lang.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text(
                              lang.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (selected) ...[
                              const Spacer(),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Text(
            AppStrings.appName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Версия ${AppStrings.appVersion}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
