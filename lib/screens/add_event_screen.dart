import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'personal';
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;

  static final _types = [
    (id: 'personal', label: 'Личное', icon: Icons.person_rounded, color: AppColors.success),
    (id: 'meeting', label: 'Встреча', icon: Icons.groups_rounded, color: AppColors.primaryLight),
    (id: 'exam', label: 'Экзамен', icon: Icons.school_rounded, color: AppColors.error),
    (id: 'other', label: 'Другое', icon: Icons.more_horiz_rounded, color: AppColors.warning),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _timeLabel {
    if (_selectedTime == null) return 'Не выбрано';
    final h = _selectedTime!.hour.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateLabel {
    if (_selectedDate == null) return 'Не выбрано';
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${_selectedDate!.day} ${months[_selectedDate!.month - 1]}';
  }

  Future<void> _pickTime() async {
    if (Platform.isIOS) {
      await _pickTimeIOS();
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (picked != null && mounted) {
        setState(() => _selectedTime = picked);
      }
    }
  }

  Future<void> _pickTimeIOS() async {
    DateTime initial = DateTime.now();
    if (_selectedTime != null) {
      initial = DateTime(
        initial.year, initial.month, initial.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );
    }
    DateTime temp = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('Готово'),
                  onPressed: () {
                    setState(() => _selectedTime = TimeOfDay(hour: temp.hour, minute: temp.minute));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initial,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    if (Platform.isIOS) {
      await _pickDateIOS();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null && mounted) {
        setState(() => _selectedDate = picked);
      }
    }
  }

  Future<void> _pickDateIOS() async {
    DateTime temp = _selectedDate ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('Готово'),
                  onPressed: () {
                    setState(() => _selectedDate = temp);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название события')),
      );
      return;
    }
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'type': _type,
      'time': _timeLabel,
      'date': _dateLabel,
      'room': _roomController.text.trim(),
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedType = _types.firstWhere((t) => t.id == _type);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Новое событие'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _onSave,
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип события
            _SectionLabel('Тип события'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: _types.map((t) {
                final isSelected = _type == t.id;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? t.color.withValues(alpha: isDark ? 0.25 : 0.12)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: isSelected ? t.color : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon, color: t.color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          t.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? t.color : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Название
            _SectionLabel('Название'),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Введите название...',
                prefixIcon: Icon(selectedType.icon, color: selectedType.color, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Дата и время
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Дата'),
                      const SizedBox(height: 10),
                      _PickerButton(
                        icon: Icons.calendar_today_rounded,
                        label: _dateLabel,
                        onTap: _pickDate,
                        hasValue: _selectedDate != null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Время'),
                      const SizedBox(height: 10),
                      _PickerButton(
                        icon: Icons.access_time_rounded,
                        label: _timeLabel,
                        onTap: _pickTime,
                        hasValue: _selectedTime != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Аудитория
            _SectionLabel('Аудитория'),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '312',
                prefixIcon: Icon(Icons.location_on_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Заметки
            _SectionLabel('Заметки'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Дополнительная информация...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: hasValue
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: hasValue ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasValue
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
