import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Кнопка диалога.
typedef AppAlertAction = AlertAction;

/// Стиль кнопки диалога (`defaultAction`, `cancel`, `destructive`, …).
typedef AppAlertActionStyle = AlertActionStyle;

/// Настройки поля ввода в диалоге.
typedef AppAlertInput = AdaptiveAlertDialogInput;

/// Диалоги приложения.
///
/// iOS 26+ — нативный алерт, iOS ≤ 18 — `CupertinoAlertDialog`,
/// Android — Material-диалог.
class AppAlertDialog {
  AppAlertDialog._();

  /// Показать диалог с произвольным набором кнопок.
  ///
  /// [icon] передаётся как [AppIcon]: на iOS 26+ используется SF Symbol,
  /// на остальных платформах — `IconData`.
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    AppIcon? icon,
    double? iconSize,
    Color? iconColor,
  }) {
    return AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      actions: actions,
      icon: _resolveIcon(icon),
      iconSize: iconSize,
      iconColor: iconColor,
    );
  }

  /// Диалог с полем ввода. Возвращает введённый текст или `null` при отмене.
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    required AdaptiveAlertDialogInput input,
    AppIcon? icon,
    double? iconSize,
    Color? iconColor,
  }) {
    return AdaptiveAlertDialog.inputShow(
      context: context,
      title: title,
      message: message,
      actions: actions,
      input: input,
      icon: _resolveIcon(icon),
      iconSize: iconSize,
      iconColor: iconColor,
    );
  }

  /// Диалог подтверждения «Отмена / Подтвердить».
  /// Возвращает `true`, если пользователь подтвердил.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    bool isDestructive = false,
    AppIcon? icon,
  }) async {
    var confirmed = false;
    await show(
      context: context,
      title: title,
      message: message,
      icon: icon,
      actions: [
        AlertAction(
          title: cancelText,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: confirmText,
          style: isDestructive
              ? AlertActionStyle.destructive
              : AlertActionStyle.defaultAction,
          onPressed: () => confirmed = true,
        ),
      ],
    );
    return confirmed;
  }

  /// iOS 26 ждёт имя SF Symbol, остальные платформы — `IconData`.
  static dynamic _resolveIcon(AppIcon? icon) => icon?.adaptive;
}
