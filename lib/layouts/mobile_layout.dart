import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Нижняя навигация — iOS 26 Liquid Glass
class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(path: '/', label: 'Главная', icon: Icons.home_rounded),
    _NavItem(
        path: '/schedule',
        label: 'Расписание',
        icon: Icons.calendar_today_rounded),
    _NavItem(
        path: '/notes',
        label: 'Конспекты',
        icon: Icons.auto_stories_rounded),
    _NavItem(path: '/profile', label: 'Профиль', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool isActive(String path) {
      if (path == '/') return location == '/' || location.isEmpty;
      return location.startsWith(path);
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 0,
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  // Liquid glass: полупрозрачный фон с лёгким тонированием
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.04),
                            Colors.white.withOpacity(0.06),
                          ]
                        : [
                            Colors.white.withOpacity(0.65),
                            Colors.white.withOpacity(0.45),
                            Colors.white.withOpacity(0.55),
                          ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  // Тонкая светящаяся граница
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.8),
                    width: 0.5,
                  ),
                  boxShadow: [
                    // Внешняя мягкая тень
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                    // Внутреннее свечение (имитация стекла)
                    if (!isDark)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 1,
                        offset: const Offset(0, -0.5),
                        spreadRadius: 0,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _navItems.map((item) {
                    final active = isActive(item.path);
                    return Expanded(
                      child: _NavTile(
                        item: item,
                        active: active,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go(item.path);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? activeColor.withOpacity(isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? activeColor : inactiveColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
  });
}
