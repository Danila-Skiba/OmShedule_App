import 'package:flutter/material.dart';

/// Линейный прогресс
class AppProgress extends StatelessWidget {
  final double value;
  final double height;

  const AppProgress({
    super.key,
    required this.value,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 100.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        // Подложка нейтральная. Раньше здесь был синий `primaryLight` из
        // палитры по умолчанию: он не следовал за акцентным цветом и в тёмной
        // теме читался как вторая, синяя полоса рядом с розовой заливкой.
        color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * (clamped / 100);
          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
