import 'package:flutter/material.dart';

/// Базовый контейнер с общими отступами, скруглением и тенью
class BaseContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const BaseContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color.fromARGB(255, 220, 220, 220),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
