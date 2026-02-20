import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Тип выбора: группа, преподаватель, аудитория
enum SelectType { group, teacher, room }

/// Экран выбора одного значения из списка (Liquid Glass стиль)
class SelectScreen extends StatelessWidget {
  final SelectType type;
  final List<String> items;
  final String? selectedId;
  final String title;

  const SelectScreen({
    super.key,
    required this.type,
    required this.items,
    this.selectedId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLg,
          vertical: AppConstants.spacingSm,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final id = items[index];
          final selected = selectedId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(id),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLg,
                    vertical: AppConstants.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.5),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          id,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
