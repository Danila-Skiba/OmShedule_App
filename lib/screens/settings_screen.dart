
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';
import '../widgets/base_container.dart';
import '../ui/adaptive/adaptive_exports.dart';

/// Настройки 
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

static const _accentOptions = [
    (id: 'blue', color: Color(0xFF6D8FAC)),   // приглушённый синий
    (id: 'green', color: Color(0xFF6F9E8C)),  // пыльный зелёный
    (id: 'purple', color: Color(0xFF8F82B3)), // мягкий серо-фиолетовый
    (id: 'rose', color: Color(0xFFB8849A)),   // припылённая роза
    (id: 'peach', color: Color(0xFFC0946E)),  // тёмный пастельный персик
    (id: 'sky', color: Color(0xFF6E9EAD)),    // дымчато-голубой
];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Настройки',
        useNativeToolbar: true,
        // Кнопку возврата ставим сами: экран открывается fade-переходом, а
        // значит свайпа «назад» у него нет, и на iOS ≤ 18 тулбар своей
        // стрелки не рисует — с настроек было не уйти.
        leading: AppToolbarLeading.back(),
      ),

    body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAppearanceSection(),
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
    final isDark = theme.brightness == Brightness.dark;
    return BaseContainer(
      isGlass: isDark,
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
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
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
                const SizedBox(height: 10),
                _ThemeToggle(
                  mode: themeMode,
                  onChanged: themeNotifier.setThemeMode,
                ),
                const SizedBox(height: 20),
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
                      onTap: () {
                        if (selected) return;
                        HapticFeedback.selectionClick();
                        themeNotifier.setAccentColor(t.color);
                      },
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

  Widget _buildAppInfo() {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        AppStrings.appName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Переключатель темы «Светлая / Тёмная».
class _ThemeToggle extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkSelected = mode == ThemeMode.dark;

    return AppSegmentedControl(
      labels: const ['Светлая', 'Тёмная'],
      selectedIndex: darkSelected ? 1 : 0,
      height: 44,
      color: theme.colorScheme.primary,
      selectedTextColor: Colors.white,
      textColor: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      onValueChanged: (index) {
        HapticFeedback.selectionClick();
        onChanged(index == 0 ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}

