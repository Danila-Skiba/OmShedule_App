import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/schedule_mock_data.dart';
import 'layouts/mobile_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/calendar_picker_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/select_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';

/// Маршрутизация (эквивалент routes.tsx createBrowserRouter)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MobileLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/schedule',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ScheduleScreen(),
          ),
          routes: [
            GoRoute(
              path: 'filter',
              pageBuilder: (context, state) {
                final extra = state.extra as FilterResult?;
                return MaterialPage<void>(
                  child: FilterScreen(initial: extra ?? const FilterResult()),
                );
              },
            ),
            GoRoute(
              path: 'select-group',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final selected = extra?['selected'] as String?;
                return MaterialPage<String?>(
                  child: SelectScreen(
                    type: SelectType.group,
                    title: 'Выберите группу',
                    items: ScheduleMockData.groupIds,
                    selectedId: selected,
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
                    items: ScheduleMockData.teacherNames,
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
                    items: ScheduleMockData.roomIds,
                    selectedId: selected,
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/maps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SettingsScreen(),
      ),
    ),
  ],
);
