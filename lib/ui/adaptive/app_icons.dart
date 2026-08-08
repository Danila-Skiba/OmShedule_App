import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/utils/platform_utils.dart';

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

  /// Материальная иконка — Android.
  final IconData icon;

  /// Иконка для iOS ≤ 18. Если не задана, используется [icon].
  ///
  /// Материальные начертания на iOS 18 выглядят чужеродно: в нижней навигации
  /// стояли залитый `home_rounded` и «квадратный» `calendar_today` вместо
  /// привычных тонких купертиновских.
  final IconData? cupertino;

  const AppIcon(this.symbol, this.icon, [this.cupertino]);

  /// Значение для `dynamic`-полей пакета (`AdaptiveNavigationDestination.icon`,
  /// `AdaptiveAlertDialog.icon`): имя SF Symbol на iOS 26+, `IconData` иначе.
  ///
  /// Нужен именно такой выбор, а не всегда строка: собственная таблица пакета
  /// «SF Symbol → CupertinoIcons» содержит около двух десятков имён, и всё
  /// незнакомое (`calendar`, `checklist`, …) превращается на iOS ≤ 18
  /// в `CupertinoIcons.circle` — пустой кружок вместо иконки.
  dynamic get adaptive {
    if (PlatformInfo.isIOS26OrHigher()) return symbol;
    return isIOS ? (cupertino ?? icon) : icon;
  }
}

/// Иконки, используемые в приложении.
class AppIcons {
  AppIcons._();

  // ── Навигация ───────────────────────────────────────────────────────────────
  static const AppIcon home =
      AppIcon('house', Icons.home_rounded, CupertinoIcons.house_fill);
  static const AppIcon schedule = AppIcon(
      'calendar', Icons.calendar_today_rounded, CupertinoIcons.calendar);
  static const AppIcon tasks = AppIcon(
      'checklist', Icons.checklist_rounded, CupertinoIcons.checkmark_circle);
  static const AppIcon maps =
      AppIcon('map', Icons.map_rounded, CupertinoIcons.map);
  static const AppIcon back = AppIcon(
      'chevron.left', Icons.arrow_back_ios_new, CupertinoIcons.back);

  // ── Действия ────────────────────────────────────────────────────────────────
  static const AppIcon settings = AppIcon(
      'gearshape', Icons.settings_rounded, CupertinoIcons.gear);
  static const AppIcon add =
      AppIcon('plus', Icons.add_rounded, CupertinoIcons.add);
  static const AppIcon close =
      AppIcon('xmark', Icons.close_rounded, CupertinoIcons.xmark);
  static const AppIcon search = AppIcon(
      'magnifyingglass', Icons.search_rounded, CupertinoIcons.search);
  static const AppIcon delete =
      AppIcon('trash', Icons.delete_outline_rounded, CupertinoIcons.delete);
  static const AppIcon edit =
      AppIcon('pencil', Icons.edit_outlined, CupertinoIcons.pencil);
  static const AppIcon refresh = AppIcon(
      'arrow.clockwise', Icons.refresh_rounded, CupertinoIcons.refresh);
  static const AppIcon share = AppIcon('square.and.arrow.up',
      Icons.ios_share_rounded, CupertinoIcons.share);
  static const AppIcon calendarPick = AppIcon(
      'calendar', Icons.calendar_month_rounded, CupertinoIcons.calendar_today);
  static const AppIcon more =
      AppIcon('ellipsis', Icons.menu, CupertinoIcons.ellipsis);
  static const AppIcon filter = AppIcon('line.3.horizontal.decrease',
      Icons.filter_list_rounded, CupertinoIcons.line_horizontal_3_decrease);
  static const AppIcon filterOff = AppIcon(
      'line.3.horizontal.decrease.circle.fill',
      Icons.filter_list_off_rounded,
      CupertinoIcons.line_horizontal_3_decrease_circle_fill);

  // ── Статусы ─────────────────────────────────────────────────────────────────
  static const AppIcon success =
      AppIcon('checkmark.circle.fill', Icons.check_circle_outline_rounded);
  static const AppIcon error =
      AppIcon('exclamationmark.circle.fill', Icons.error_outline_rounded);
  static const AppIcon warning =
      AppIcon('exclamationmark.triangle.fill', Icons.warning_amber_rounded);
  static const AppIcon info = AppIcon('info.circle', Icons.info_outline_rounded);
}
