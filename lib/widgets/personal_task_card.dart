import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/personal_task.dart';

/// Карточка личной задачи.
///
/// Слева — акцентная полоса, она же индикатор выполнения: у завершённой
/// задачи гаснет вместе с остальной карточкой. Время вынесено в пилюлю,
/// чтобы взгляд цеплялся за него первым — карточки в списке идут по времени.
class PersonalTaskCard extends StatelessWidget {
  final PersonalTask task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onDelete;
  final bool showCompletedToggle;

  const PersonalTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleCompleted,
    this.onDelete,
    this.showCompletedToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final done = task.completed;

    final accent = isDark ? const Color(0xFFB49AFF) : AppColors.taskAccent;
    // Выполненная задача уходит на второй план — приглушаем целиком.
    final accentColor = done ? accent.withValues(alpha: 0.45) : accent;
    final onSurface = theme.colorScheme.onSurface;

    final radius = BorderRadius.circular(18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.hintTaskDark : AppColors.hintTask,
            borderRadius: radius,
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.55),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Акцентная полоса во всю высоту карточки
                  Container(width: 4, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showCompletedToggle) ...[
                            _CompleteButton(
                              done: done,
                              accent: accent,
                              onTap: onToggleCompleted,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _TimePill(
                                      time: task.time,
                                      accent: accentColor,
                                      muted: done,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Личное',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  task.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: done
                                        ? onSurface.withValues(alpha: 0.45)
                                        : onSurface,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor:
                                        onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                                if (task.audience != null &&
                                    task.audience!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.audience!,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: onSurface.withValues(
                                        alpha: done ? 0.4 : 0.65,
                                      ),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 4),
                            _DeleteButton(onTap: onDelete!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кружок «выполнено» с заливкой в состоянии done.
class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.done,
    required this.accent,
    required this.onTap,
  });

  final bool done;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: done ? AppColors.success : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? AppColors.success : accent.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Время задачи — самый заметный элемент карточки.
class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.time,
    required this.accent,
    required this.muted,
  });

  final String time;
  final Color accent;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: muted ? 0.10 : 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: accent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
