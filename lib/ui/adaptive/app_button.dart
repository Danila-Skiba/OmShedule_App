import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Стиль кнопки — переэкспорт типов пакета, чтобы экраны не знали о нём.
typedef AppButtonStyle = AdaptiveButtonStyle;

/// Размер кнопки: `small` 28pt, `medium` 36pt (по умолчанию), `large` 44pt.
typedef AppButtonSize = AdaptiveButtonSize;

/// Кнопка приложения.
///
/// iOS 26+ — нативная Liquid Glass кнопка, iOS ≤ 18 — `CupertinoButton`,
/// Android — Material.
///
/// ⚠️ На iOS 26 это `UiKitView` (отдельный нативный слой композитора).
/// **Не использовать внутри `ListView.builder`, `GridView`, `SliverList`
/// и других лениво строящихся списков** — гарантированная просадка скролла.
/// Ориентир: не более 3–5 нативных компонентов на экране.
class AppButton extends StatelessWidget {
  /// Текстовая кнопка.
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.style = AdaptiveButtonStyle.filled,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.enabled = true,
  })  : child = null,
        icon = null,
        iconColor = null;

  /// Кнопка с произвольным содержимым.
  const AppButton.child({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = AdaptiveButtonStyle.filled,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.padding,
    this.borderRadius,
    this.enabled = true,
  })  : label = null,
        textColor = null,
        icon = null,
        iconColor = null;

  /// Кнопка-иконка.
  const AppButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.style = AdaptiveButtonStyle.plain,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.iconColor,
    this.padding,
    this.borderRadius,
    this.enabled = true,
  })  : label = null,
        child = null,
        textColor = null;

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final AdaptiveButtonStyle style;
  final AdaptiveButtonSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return AdaptiveButton.icon(
        onPressed: onPressed,
        icon: icon,
        style: style,
        size: size,
        color: color,
        iconColor: iconColor,
        padding: padding,
        borderRadius: borderRadius,
        enabled: enabled,
      );
    }
    if (child != null) {
      return AdaptiveButton.child(
        onPressed: onPressed,
        style: style,
        size: size,
        color: color,
        padding: padding,
        borderRadius: borderRadius,
        enabled: enabled,
        child: child!,
      );
    }
    return AdaptiveButton(
      onPressed: onPressed,
      label: label!,
      style: style,
      size: size,
      color: color,
      textColor: textColor,
      padding: padding,
      borderRadius: borderRadius,
      enabled: enabled,
    );
  }
}
