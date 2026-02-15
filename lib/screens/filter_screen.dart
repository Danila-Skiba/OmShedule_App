import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/schedule_mock_data.dart';

/// Результат выбора фильтров (множественный выбор)
class FilterResult {
  final Set<String> selectedGroupIds;
  final Set<String> selectedTeacherNames;
  final Set<String> selectedRoomIds;

  const FilterResult({
    this.selectedGroupIds = const {},
    this.selectedTeacherNames = const {},
    this.selectedRoomIds = const {},
  });
}

/// Экран фильтров: три вкладки, поиск, множественный выбор, кнопки Применить / Сбросить
class FilterScreen extends StatefulWidget {
  final FilterResult initial;

  const FilterScreen({super.key, required this.initial});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<String> _selectedGroups;
  late Set<String> _selectedTeachers;
  late Set<String> _selectedRooms;
  String _searchGroups = '';
  String _searchTeachers = '';
  String _searchRooms = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedGroups = Set.from(widget.initial.selectedGroupIds);
    _selectedTeachers = Set.from(widget.initial.selectedTeacherNames);
    _selectedRooms = Set.from(widget.initial.selectedRoomIds);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get _filteredGroups {
    final q = _searchGroups.trim().toLowerCase();
    if (q.isEmpty) return ScheduleMockData.groupIds;
    return ScheduleMockData.groupIds.where((id) => id.toLowerCase().contains(q)).toList();
  }

  List<String> get _filteredTeachers {
    final q = _searchTeachers.trim().toLowerCase();
    if (q.isEmpty) return ScheduleMockData.teacherNames;
    return ScheduleMockData.teacherNames.where((n) => n.toLowerCase().contains(q)).toList();
  }

  List<String> get _filteredRooms {
    final q = _searchRooms.trim().toLowerCase();
    if (q.isEmpty) return ScheduleMockData.roomIds;
    return ScheduleMockData.roomIds.where((id) => id.toLowerCase().contains(q)).toList();
  }

  void _apply() {
    Navigator.of(context).pop(FilterResult(
      selectedGroupIds: _selectedGroups,
      selectedTeacherNames: _selectedTeachers,
      selectedRoomIds: _selectedRooms,
    ));
  }

  void _reset() {
    setState(() {
      _selectedGroups.clear();
      _selectedTeachers.clear();
      _selectedRooms.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Фильтры'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Группы'),
            Tab(text: 'Преподаватели'),
            Tab(text: 'Аудитории'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabContent(
                  searchQuery: _searchGroups,
                  onSearchChanged: (v) => setState(() => _searchGroups = v),
                  items: _filteredGroups,
                  selectedIds: _selectedGroups,
                  onToggle: (id) {
                    setState(() {
                      if (_selectedGroups.contains(id)) {
                        _selectedGroups.remove(id);
                      } else {
                        _selectedGroups.add(id);
                      }
                    });
                  },
                ),
                _TabContent(
                  searchQuery: _searchTeachers,
                  onSearchChanged: (v) => setState(() => _searchTeachers = v),
                  items: _filteredTeachers,
                  selectedIds: _selectedTeachers,
                  onToggle: (id) {
                    setState(() {
                      if (_selectedTeachers.contains(id)) {
                        _selectedTeachers.remove(id);
                      } else {
                        _selectedTeachers.add(id);
                      }
                    });
                  },
                ),
                _TabContent(
                  searchQuery: _searchRooms,
                  onSearchChanged: (v) => setState(() => _searchRooms = v),
                  items: _filteredRooms,
                  selectedIds: _selectedRooms,
                  onToggle: (id) {
                    setState(() {
                      if (_selectedRooms.contains(id)) {
                        _selectedRooms.remove(id);
                      } else {
                        _selectedRooms.add(id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          _BottomButtons(
            onApply: _apply,
            onReset: _reset,
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<String> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _TabContent({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Поиск по названию',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final id = items[index];
              final selected = selectedIds.contains(id);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onToggle(id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (_) => onToggle(id),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            id,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _BottomButtons({required this.onApply, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Сбросить'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
