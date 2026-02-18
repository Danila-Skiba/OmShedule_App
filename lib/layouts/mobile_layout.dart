import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

/// Нижняя навигация
class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(path: '/', label: 'Главная', icon: Icons.home_rounded),
    _NavItem(path: '/schedule', label: 'Расписание', icon: Icons.calendar_today_rounded),
    // _NavItem(path: '/maps', label: 'Карты', icon: Icons.map_rounded),
    _NavItem(path: '/profile', label: 'Профиль', icon: Icons.person_rounded),
    _NavItem(path: '/chat', label: 'Помощник', icon: Icons.chat_bubble_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    bool isActive(String path) {
      if (path == '/') return location == '/' || location.isEmpty;
      return location.startsWith(path);
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: child,
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Container(
                height: 56, 
                padding: const EdgeInsets.symmetric(horizontal: 12), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _navItems.map((item) {
                    final active = isActive(item.path);
                    return Expanded(
                      child: InkWell(
                        onTap: () => context.go(item.path),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: active ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 2), 
                              Flexible(
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: active ? AppColors.primary : AppColors.textSecondary,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  const _NavItem({required this.path, required this.label, required this.icon});
}