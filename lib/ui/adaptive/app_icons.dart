import 'package:flutter/material.dart';

/// Единый словарь соответствий `IconData` ↔ SF Symbol.
///
/// На iOS 26+ нативные тулбары и алерты пакета ждут **строку** с именем
/// SF Symbol, на iOS ≤ 18 и Android — обычную `IconData`. Чтобы тернарники
/// не расползались по экранам, всё сопоставление живёт здесь.
///
/// Использование:
/// ```dart
/// AdaptiveAppBarAction(
///   iosSymbol: AppIcons.settings.symbol,  // используется только на iOS 26+
///   icon: AppIcons.settings.icon,         // iOS ≤ 18 и Android
///   onPressed: () {},
/// )
/// ```
class AppIcon {
  /// Имя SF Symbol (например, `gearshape`).
  final String symbol;

  /// Материальная иконка-фолбэк.
  final IconData icon;

  const AppIcon(this.symbol, this.icon);
}

/// Иконки, используемые в приложении.
class AppIcons {
  AppIcons._();

  // ── Навигация ───────────────────────────────────────────────────────────────
  static const AppIcon home = AppIcon('house', Icons.home_rounded);
  static const AppIcon schedule =
      AppIcon('calendar', Icons.calendar_today_rounded);
  static const AppIcon tasks = AppIcon('checklist', Icons.checklist_rounded);
  static const AppIcon maps = AppIcon('map', Icons.map_rounded);
  static const AppIcon back = AppIcon('chevron.left', Icons.arrow_back_ios_new);

  // ── Действия ────────────────────────────────────────────────────────────────
  static const AppIcon settings = AppIcon('gearshape', Icons.settings_rounded);
  static const AppIcon add = AppIcon('plus', Icons.add_rounded);
  static const AppIcon close = AppIcon('xmark', Icons.close_rounded);
  static const AppIcon search = AppIcon('magnifyingglass', Icons.search_rounded);
  static const AppIcon delete = AppIcon('trash', Icons.delete_outline_rounded);
  static const AppIcon edit = AppIcon('pencil', Icons.edit_outlined);
  static const AppIcon refresh =
      AppIcon('arrow.clockwise', Icons.refresh_rounded);
  static const AppIcon share =
      AppIcon('square.and.arrow.up', Icons.ios_share_rounded);
  static const AppIcon calendarPick =
      AppIcon('calendar.badge.clock', Icons.event_rounded);

  // ── Статусы ─────────────────────────────────────────────────────────────────
  static const AppIcon success =
      AppIcon('checkmark.circle.fill', Icons.check_circle_outline_rounded);
  static const AppIcon error =
      AppIcon('exclamationmark.circle.fill', Icons.error_outline_rounded);
  static const AppIcon warning =
      AppIcon('exclamationmark.triangle.fill', Icons.warning_amber_rounded);
  static const AppIcon info = AppIcon('info.circle', Icons.info_outline_rounded);
}
