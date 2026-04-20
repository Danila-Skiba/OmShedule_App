import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Тип выбора: группа, преподаватель, аудитория
enum SelectType { group, teacher, room }

/// Экран выбора одного значения из списка с поиском
class SelectScreen extends StatefulWidget {
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
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final _searchController = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _hintForType(widget.type),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Количество результатов
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Найдено: ${_filtered.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          // Список
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ничего не найдено',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingLg,
                      vertical: AppConstants.spacingSm,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final id = _filtered[index];
                      final selected = widget.selectedId == id;
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppConstants.spacingSm),
                        child: Material(
                          color: theme.cardColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(id),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingLg,
                                vertical: AppConstants.spacingMd,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMd),
                                border: Border.all(
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor
                                          .withValues(alpha: 0.5),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      id,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
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
          ),
        ],
      ),
    );
  }

  String _hintForType(SelectType type) {
    switch (type) {
      case SelectType.group:
        return 'Поиск группы...';
      case SelectType.teacher:
        return 'Поиск преподавателя...';
      case SelectType.room:
        return 'Поиск аудитории...';
    }
  }
}
