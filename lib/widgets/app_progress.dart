import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Линейный прогресс (эквивалент Progress из progress.tsx Radix UI)
class AppProgress extends StatelessWidget {
  final double value; // 0.0 - 100.0
  final double height;

  const AppProgress({
    super.key,
    required this.value,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
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
                    color: Theme.of(context).colorScheme.primary,
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
