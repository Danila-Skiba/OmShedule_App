import 'package:flutter/material.dart';

/// Единый привлекательный диалог для всего приложения.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final bool isDanger;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.message,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    this.onConfirm,
    this.isDanger = false,
  });

  /// Удобный статический метод для вызова.
  static Future<bool?> show({
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    required String title,
    String? message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    VoidCallback? onConfirm,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => AppDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final accentColor = isDanger
        ? theme.colorScheme.error
        : (iconColor ?? primary);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: isDark ? 0 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            if (icon != null) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: accentColor),
              ),
              const SizedBox(height: 18),
            ],

            // Заголовок
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: onSurface,
                height: 1.3,
              ),
            ),

            // Описание
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                // Отмена
                Expanded(
                  child: Material(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Подтвердить
                Expanded(
                  child: Material(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(true);
                        onConfirm?.call();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
