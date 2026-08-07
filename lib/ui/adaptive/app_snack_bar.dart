import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Тип уведомления (`info`, `success`, `warning`, `error`).
typedef AppSnackBarType = AdaptiveSnackBarType;

/// Короткое уведомление.
///
/// ⚠️ На iOS показывается баннером **сверху**, на Android — снизу.
/// Логику, завязанную на позицию, проверяйте отдельно.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AdaptiveSnackBarType type = AdaptiveSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? action,
    VoidCallback? onActionPressed,
  }) {
    AdaptiveSnackBar.show(
      context,
      message: message,
      type: type,
      duration: duration,
      action: action,
      onActionPressed: onActionPressed,
    );
  }

  /// Уведомление об успехе.
  static void success(BuildContext context, String message) {
    show(context, message: message, type: AdaptiveSnackBarType.success);
  }

  /// Уведомление об ошибке.
  static void error(BuildContext context, String message) {
    show(context, message: message, type: AdaptiveSnackBarType.error);
  }
}
