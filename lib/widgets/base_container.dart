import 'dart:ui';

import 'package:flutter/material.dart';

/// Базовый контейнер с общими отступами, скруглением и тенью.
/// При `isGlass: true` — iOS 26 liquid glass эффект.
///
/// Фон вынесен в отдельный слой `Stack` и лежит **рядом** с содержимым, а не
/// оборачивает его. Это принципиально: `isGlass` почти всегда завязан на
/// `isDark`, и если бы стеклянная ветка добавляла обёртки над содержимым
/// (`ClipRRect` → `BackdropFilter`), то при смене темы структура дерева
/// менялась бы, Flutter выбрасывал бы всё поддерево и строил заново.
/// Для нативных platform view (`AppSegmentedControl`, `AppSwitch` на iOS 26)
/// это означало пересоздание нативной вьюхи и потерю её анимации —
/// переключатель темы в настройках дёргался именно поэтому.
///
/// Поэтому содержимое всегда находится на одной и той же позиции в дереве
/// (второй ребёнок `Stack`), а от темы зависит только фон — первый ребёнок.
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

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Stack(
        fit: StackFit.passthrough,
        // Внешние констрейнты проходят к содержимому без изменений — как это
        // делал обычный Container раньше. Без этого в горизонтальном списке
        // (фильтры «Группа/Аудитория/…») контейнеру приходит жёсткая высота,
        // а содержимое сжималось по своему размеру и прилипало к верху.
        children: [
          // Фон. Меняется вместе с темой — и пусть: содержимого он не касается.
          Positioned.fill(
            child: _buildBackground(theme, isDark, borderRadius),
          ),
          // Содержимое. Всегда одна и та же позиция и тип — поддерево
          // переживает смену темы, нативные вьюхи не пересоздаются.
          SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(
    ThemeData theme,
    bool isDark,
    BorderRadius borderRadius,
  ) {
    if (!isGlass) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isDark || !shadow
              ? null
              : [
                  const BoxShadow(
                    color: Color.fromARGB(80, 148, 163, 184),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.45),
                    ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.7),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
