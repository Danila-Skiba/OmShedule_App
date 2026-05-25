import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/utils/platform_utils.dart';

/// Переключатель: CupertinoSwitch на iOS, Material Switch на Android. // iOS
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
    if (isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}
