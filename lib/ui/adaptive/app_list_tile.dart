import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Строка списка.
///
/// iOS — стиль inset-grouped, Android — Material `ListTile`.
/// Для последнего элемента секции ставьте [hideBottomDivider].
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.hideBottomDivider = false,
    this.backgroundColor,
    this.separatorColor,
    this.padding,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;

  /// Скрыть нижний разделитель — для последнего элемента секции.
  final bool hideBottomDivider;
  final Color? backgroundColor;
  final Color? separatorColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      selected: selected,
      hideBottomDivider: hideBottomDivider,
      backgroundColor: backgroundColor,
      separatorColor: separatorColor,
      padding: padding,
    );
  }
}
