import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Переключатель.
///
/// iOS 26+ — нативный `UISwitch`, iOS ≤ 18 — `CupertinoSwitch`,
/// Android — Material `Switch`.
///
/// ⚠️ На iOS 26 это `UiKitView`. В ячейках лениво строящихся списков
/// не использовать (см. стоп-правило 1 в `tasks/TaskLiquidGlass.md`).
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.thumbColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? thumbColor;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      thumbColor: thumbColor,
    );
  }
}
