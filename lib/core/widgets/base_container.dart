import 'dart:ui';

import 'package:flutter/material.dart';

/// Базовый контейнер с общими отступами, скруглением и тенью
class BaseContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool isGlass;

  const BaseContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: isGlass
            ? (isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.28))
            : backgroundColor ?? theme.cardColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: isGlass
              ? Colors.white.withOpacity(isDark ? 0.18 : 0.35)
              : (isDark ? theme.colorScheme.outline : const Color(0xFFE2E8F0)),
        ),
        boxShadow: isGlass || isDark
            ? null
            : const [
                BoxShadow(
                  color: Color.fromARGB(80, 148, 163, 184),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );

    if (!isGlass) return content;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: content,
      ),
    );
  }
}
