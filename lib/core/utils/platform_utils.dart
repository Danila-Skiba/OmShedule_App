import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ─── Platform Detection ───────────────────────────────────────────────── // iOS
final bool isIOS = Platform.isIOS;

// ─── Loading Indicator ────────────────────────────────────────────────── // iOS
/// CupertinoActivityIndicator на iOS, CircularProgressIndicator на Android.
Widget buildLoader({double? radius, double? strokeWidth, Color? color}) {
  if (isIOS) {
    return CupertinoActivityIndicator(radius: radius ?? 14, color: color);
  }
  return CircularProgressIndicator(
    strokeWidth: strokeWidth ?? 4.0,
    color: color,
  );
}

/// Маленький лоадер (для кнопок и т.п.).
Widget buildSmallLoader({Color? color}) {
  if (isIOS) {
    return CupertinoActivityIndicator(radius: 10, color: color);
  }
  return SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
  );
}

// ─── Navigation Transitions ──────────────────────────────────────────── // iOS
/// CupertinoPageRoute на iOS, MaterialPageRoute на Android.
Route<T> buildRoute<T>(Widget page) {
  if (isIOS) {
    return CupertinoPageRoute<T>(builder: (_) => page);
  }
  return MaterialPageRoute<T>(builder: (_) => page);
}

// ─── AppBar ───────────────────────────────────────────────────────────── // iOS
/// CupertinoNavigationBar на iOS, AppBar на Android.
PreferredSizeWidget buildAppBar({
  required BuildContext context,
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  Widget? leading,
  bool automaticallyImplyLeading = true,
  Color? backgroundColor,
}) {
  if (isIOS) {
    final theme = Theme.of(context);
    return CupertinoNavigationBar(
      middle: titleWidget ??
          (title != null
              ? Text(title, style: TextStyle(color: theme.colorScheme.onSurface))
              : null),
      leading: leading,
      trailing: actions != null && actions.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: actions)
          : null,
      backgroundColor:
          backgroundColor ?? theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
  return AppBar(
    title: titleWidget ?? (title != null ? Text(title) : null),
    actions: actions,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
  );
}
