import 'package:flutter/material.dart';

/// Красивый кастомный SnackBar для всего приложения.
/// Использует акцентный цвет из темы, без тени, без анимации выезда снизу.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Фон — плотный, хорошо видимый
    final accentColor = isError ? theme.colorScheme.error : primary;
    final bgColor = isDark
        ? Color.alphaBlend(accentColor.withValues(alpha: 0.25), const Color(0xFF252528))
        : Color.alphaBlend(accentColor.withValues(alpha: 0.12), const Color(0xFFFAFAFA));
    final borderColor = accentColor.withValues(alpha: isDark ? 0.6 : 0.4);
    final iconColor = accentColor;
    final textColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        animation: _noSlideAnimation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Анимация без выезда снизу — просто fade in/out.
  static final CurvedAnimation _noSlideAnimation = CurvedAnimation(
    parent: const AlwaysStoppedAnimation(1.0),
    curve: Curves.linear,
  );

  /// Короткое уведомление об успехе.
  static void success(BuildContext context, String message) {
    show(context,
        message: message,
        icon: Icons.check_circle_outline_rounded);
  }

  /// Уведомление об ошибке.
  static void error(BuildContext context, String message) {
    show(context,
        message: message,
        icon: Icons.error_outline_rounded,
        isError: true);
  }
}
