import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../ui/adaptive/adaptive_exports.dart';

/// Нижняя навигация.
///
/// iOS 26+ — нативный `UITabBar` с Liquid Glass ([AppNativeTabBar], который
/// добавляет к нему обработку одиночного нажатия), iOS ≤ 18 — `CupertinoTabBar`,
/// собранный здесь же (см. комментарий в `build`).
class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      path: '/',
      label: 'Главная',
      icon: AppIcons.home,
      cupertinoIcon: CupertinoIcons.house,
      cupertinoActiveIcon: CupertinoIcons.house_fill,
    ),
    _NavItem(
      path: '/schedule',
      label: 'Расписание',
      icon: AppIcons.schedule,
      cupertinoIcon: CupertinoIcons.calendar,
      cupertinoActiveIcon: CupertinoIcons.calendar_today,
    ),
    _NavItem(
      path: '/tasks',
      label: 'Задачи',
      icon: AppIcons.tasks,
      cupertinoIcon: CupertinoIcons.checkmark_circle,
      cupertinoActiveIcon: CupertinoIcons.checkmark_circle_fill,
    ),
  ];

  /// Индекс активной вкладки. Для `/maps` (экран внутри шелла, но без своей
  /// вкладки) совпадения нет — подсвечиваем «Главную», потому что нативный
  /// таб-бар требует валидный индекс.
  static int _selectedIndex(String location) {
    for (var i = _navItems.length - 1; i >= 0; i--) {
      final path = _navItems[i].path;
      if (path == '/') {
        if (location == '/' || location.isEmpty) return i;
      } else if (location.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final selectedIndex = _selectedIndex(location);
    const unselectedColor = Color(0xFF8E8E93);

    void openTab(int index) {
      final path = _navItems[index].path;
      if (path == location) return;
      HapticFeedback.lightImpact();
      context.go(path);
    }

    final destinations = _navItems
        .map(
          (item) => AppNavigationDestination(
            icon: item.icon.adaptive,
            label: item.label,
          ),
        )
        .toList();

    // iOS ≤ 18 — обычный CupertinoTabBar из пакета: там нативного вида нет,
    // нажатия работают штатно, обходной слой не нужен.
    if (!PlatformInfo.isIOS26OrHigher()) {
      // Панель собираем сами, а не отдаём пакету на автогенерацию: он строит
      // `CupertinoTabBar` с иконками по 30 pt и одним начертанием на оба
      // состояния. На iOS 18 это выглядело чужеродно — крупные заливки без
      // пары «контур/заливка». Здесь же задаём привычные 26 pt и разные
      // иконки для активной и неактивной вкладки, как в системных приложениях.
      final cupertinoTabBar = CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: openTab,
        activeColor: theme.colorScheme.primary,
        inactiveColor: unselectedColor,
        iconSize: 26,
        items: _navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.cupertinoIcon),
                activeIcon: Icon(item.cupertinoActiveIcon),
                label: item.label,
              ),
            )
            .toList(),
      );

      return AppScaffold(
        // Панель прижата к нижней кромке и уходит под клавиатуру — как в
        // системных приложениях. См. комментарий в ветке iOS 26 ниже.
        resizeToAvoidBottomInset: false,
        body: child,
        bottomNavigationBar: AppBottomNavigationBar(
          useNativeBottomBar: false,
          selectedIndex: selectedIndex,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: unselectedColor,
          items: destinations,
          onTap: openTab,
          cupertinoTabBar: cupertinoTabBar,
        ),
      );
    }

    // iOS 26+ — нативный таб-бар размещаем сами, чтобы положить поверх него
    // слой обработки тапов (см. AppNativeTabBar). Раскладка повторяет ту,
    // что делает AdaptiveScaffold: панель прижата к нижней кромке поверх тела.
    return Scaffold(
      extendBody: true,
      // Панель лежит в `Positioned(bottom: 0)`, поэтому при включённом
      // resize она поднималась вместе с телом и повисала над клавиатурой
      // (заметнее всего в поиске по фильтрам). Отключаем resize: окно
      // клавиатуры имеет более высокий z-order и просто накрывает панель —
      // именно так ведут себя системные приложения. Экраны внутри шелла
      // отодвигают своё содержимое сами, у каждого свой каркас.
      //
      // Ровно так же поступает и AdaptiveScaffold, когда таб-бар отдан ему
      // (`resizeToAvoidBottomInset ?? !hasBottomNav`), но здесь панель
      // размещаем мы, и настройка по умолчанию досталась от Scaffold.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNativeTabBar(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onTap: openTab,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: unselectedColor,
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

  /// Иконка для нативной панели iOS 26 и для Android.
  final AppIcon icon;

  /// Пара иконок для `CupertinoTabBar` на iOS ≤ 18: контурная у неактивной
  /// вкладки, залитая у активной.
  final IconData cupertinoIcon;
  final IconData cupertinoActiveIcon;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.cupertinoIcon,
    required this.cupertinoActiveIcon,
  });
}
