import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omstu_schedule/data/schedule_data.dart';
import 'layouts/mobile_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_picker_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/select_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lecture_notes_screen.dart';
import 'screens/auth_screen.dart';

/// Плавный переход между вкладками (fade).
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
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
            // GoRoute(
            //   path: 'filter',
            //   pageBuilder: (context, state) {
            //     final extra = state.extra as FilterResult?;
            //     return MaterialPage<void>(
            //       child: FilterScreen(initial: extra ?? const FilterResult()),
            //     );
            //   },
            // ),
            GoRoute(
              path: 'select-group',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return MaterialPage<String?>(
                  child: SelectScreen(
                    type: SelectType.group,
                    title: 'Выберите группу',
                    items: ScheduleData.getgroups.keys.toList(),              selectedId: selected,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'select-teacher',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return MaterialPage<String?>(
                  child: SelectScreen(
                    type: SelectType.teacher,
                    title: 'Выберите преподавателя',
                    items: ScheduleData.getpersons.keys.toList(),
                    selectedId: selected,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'calendar',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final initialDate = extra?['initialDate'] as DateTime?;
                return MaterialPage<DateTime?>(
                  child: CalendarPickerScreen(initialDate: initialDate),
                );
              },
            ),
            GoRoute(
              path: 'select-room',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return MaterialPage<String?>(
                  child: SelectScreen(
                    type: SelectType.room,
                    title: 'Выберите аудиторию',
                    items: ScheduleData.getauditorium.keys.toList(),
                    selectedId: selected,
                  ),
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
          path: '/notes',
          pageBuilder: (context, state) =>
              _fadePage(const LectureNotesScreen(), state),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              _fadePage(const ProfileScreen(), state),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) =>
              _fadePage(const ChatScreen(), state),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadePage(const SettingsScreen(), state),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) =>
          _fadePage(const AuthScreen(), state),
    ),
  ],
);
