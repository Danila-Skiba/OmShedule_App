import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Сегментированный переключатель («День / Неделя», «Светлая / Тёмная»).
///
/// iOS 26+ — нативный `UISegmentedControl` с Liquid Glass,
/// iOS ≤ 18 — `CupertinoSlidingSegmentedControl`,
/// Android — Material `SegmentedButton`.
///
/// ⚠️ На iOS 26 это `UiKitView`. В ячейках лениво строящихся списков
/// не использовать (см. стоп-правило 1 в `tasks/TaskLiquidGlass.md`).
///
/// Иконки намеренно не пробрасываются: у `AdaptiveSegmentedControl` режим
/// `sfSymbols` **заменяет** подписи, а не дополняет их, — поэтому сегменты
/// здесь всегда текстовые.
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    this.color,
    this.height = 36.0,
    this.textColor,
    this.selectedTextColor,
  });

  /// Подписи сегментов по порядку.
  final List<String> labels;

  /// Индекс выбранного сегмента.
  final int selectedIndex;

  /// Вызывается при выборе сегмента.
  final ValueChanged<int> onValueChanged;

  /// Цвет «пилюли» под выбранным сегментом.
  final Color? color;

  final double height;

  /// Цвет подписи невыбранного сегмента.
  final Color? textColor;

  /// Цвет подписи выбранного сегмента.
  final Color? selectedTextColor;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSegmentedControl(
      labels: labels,
      selectedIndex: selectedIndex,
      onValueChanged: onValueChanged,
      color: color,
      height: height,
      textColor: textColor,
      selectedTextColor: selectedTextColor,
    );
  }
}
