import 'dart:ui';

import 'package:flutter/material.dart';

/// Базовый контейнер с общими отступами, скруглением и тенью.
/// При `isGlass: true` — iOS 26 liquid glass эффект.
class BaseContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool isGlass;
  final bool shadow;

  const BaseContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isGlass = false,
    this.shadow = true
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
            ? (isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.45))
            : backgroundColor ?? theme.cardColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: isGlass
              ? (isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.7))
              : (isDark ? theme.colorScheme.outline : const Color(0xFFE2E8F0)),
          width: isGlass ? 0.5 : 1.0,
        ),
        gradient: isGlass
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.55),
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.45),
                      ],
              )
            : null,
        boxShadow: isGlass
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ]
            : (isDark || !shadow
                ? null
                : [
                    const BoxShadow(
                      color: Color.fromARGB(80, 148, 163, 184),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ]),
      ),
      child: child,
    );

    if (!isGlass) return content;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.55),
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.45),
                      ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.7),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
