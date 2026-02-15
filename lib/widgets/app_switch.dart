import 'package:flutter/material.dart';

/// Переключатель (эквивалент Switch из switch.tsx Radix UI).
/// value + onChanged соответствуют checked + onCheckedChange.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}
