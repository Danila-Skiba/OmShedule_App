import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

/// Нижняя навигация
class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(path: '/', label: 'Главная', icon: Icons.home_rounded),
    _NavItem(path: '/schedule', label: 'Расписание', icon: Icons.calendar_today_rounded),
    _NavItem(path: '/profile', label: 'Профиль', icon: Icons.person_rounded),
    // _NavItem(path: '/chat', label: 'Помощник', icon: Icons.chat_bubble_rounded),
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
  child: SafeArea(
    
    bottom: false, 
    child: Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        boxShadow: const [ 
                BoxShadow(
                  color: Color.fromARGB(80, 148, 163, 184),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],

      ),
      padding: const EdgeInsets.all(0),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.map((item) {
          final active = isActive(item.path);
          return Expanded(
            child: _NavTile(
              item: item,
              active: active,
              onTap: () => context.go(item.path),
            ),
          );
        }).toList(),
      ),
    ),
  ),
)
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
    final activeColor = theme.colorScheme.primary;
    const inactiveColor =  Colors.black;
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: AppConstants.iconSizeNav,
                color: active ? activeColor : inactiveColor,
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
    required this.icon
  });
}