import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/data/schedule_data.dart';
import 'core/utils/platform_utils.dart';
import 'layouts/mobile_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_picker_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/select_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/settings_screen.dart';

/// Плавный переход между вкладками (fade).
///
/// Вкладки — соседи, а не вложенные экраны, поэтому боковой сдвиг здесь был бы
/// неуместен: в системных приложениях вкладки тоже сменяются без него.
/// `easeInOut` вместо линейной кривой — переход перестаёт «щёлкать» на краях.
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

/// Страница-экран поверх текущего: на iOS — сдвиг справа со свайпом назад,
/// на Android — материальный переход.
///
/// Раньше все экраны, включая настройки и экраны выбора, открывались тем же
/// fade, что и вкладки: жеста «назад» у них не было, а нативные части
/// (стеклянный тулбар, сегментированный контрол) в прозрачность не
/// анимируются и появлялись рывком, когда остальное уже проявилось.
Page<T> _platformPage<T>(Widget child, GoRouterState state) {
  if (isIOS) {
    return CupertinoPage<T>(key: state.pageKey, child: child);
  }
  return MaterialPage<T>(key: state.pageKey, child: child);
}

/// Маршрутизация (эквивалент routes.tsx createBrowserRouter)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MobileLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _fadePage(const DashboardScreen(), state),
        ),
        GoRoute(
          path: '/schedule',
          pageBuilder: (context, state) =>
              _fadePage(const ScheduleScreen(), state),
          routes: [
            GoRoute(
              path: 'select-group',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return _platformPage<String?>(
                  SelectScreen(
                    type: SelectType.group,
                    title: 'Выберите группу',
                    items: ScheduleData.groups,
                    selectedId: selected,
                  ),
                  state,
                );
              },
            ),
            GoRoute(
              path: 'select-teacher',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return _platformPage<String?>(
                  SelectScreen(
                    type: SelectType.teacher,
                    title: 'Выберите преподавателя',
                    items: ScheduleData.persons,
                    selectedId: selected,
                  ),
                  state,
                );
              },
            ),
            GoRoute(
              path: 'calendar',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final initialDate = extra?['initialDate'] as DateTime?;
                return _platformPage<DateTime?>(
                  CalendarPickerScreen(initialDate: initialDate),
                  state,
                );
              },
            ),
            GoRoute(
              path: 'select-room',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return _platformPage<String?>(
                  SelectScreen(
                    type: SelectType.room,
                    title: 'Выберите аудиторию',
                    items: ScheduleData.auditoriums,
                    selectedId: selected,
                  ),
                  state,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/maps',
          pageBuilder: (context, state) =>
              _fadePage(const MapsScreen(), state),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) =>
              _fadePage(const TasksScreen(), state),
        ),
      ],
    ),
    // Настройки лежат вне шелла, поэтому открываются поверх него целиком.
    // Боковой сдвиг здесь смотрелся сломанным: нижняя навигация на iOS 26 —
    // нативный `UiKitView`, отдельный слой композитора, и в анимации страницы
    // он не участвует — панель оставалась висеть поверх уезжающего экрана.
    // Fade такого расслоения не создаёт: оба экрана остаются на месте.
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadePage(const SettingsScreen(), state),
    ),
  ],
);
