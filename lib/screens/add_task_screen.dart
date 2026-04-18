import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../core/services/task_service.dart';
import '../models/personal_task.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime forDate;

  const AddTaskScreen({super.key, required this.forDate});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _audienceController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.forDate;
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    if (Platform.isIOS) {
      await _pickTimeCupertino();
    } else {
      await _pickTimeMaterial();
    }
  }

  Future<void> _pickTimeCupertino() async {
    final initial = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    TimeOfDay? result;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        DateTime temp = initial;
        return Container(
          height: 300,
          color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                      result = TimeOfDay(hour: temp.hour, minute: temp.minute);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initial,
                  use24hFormat: true,
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _selectedTime = result!);
    }
  }

  Future<void> _pickTimeMaterial() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final task = PersonalTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      time: _formatTimeOfDay(_selectedTime),
      audience: _audienceController.text.trim().isNotEmpty
          ? _audienceController.text.trim()
          : null,
      date: _formatDate(_selectedDate),
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await TaskService.instance.saveTask(task);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Новая задача'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            _SectionLabel(label: 'Название задачи', theme: theme),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Встреча, задача, напоминание...',
                prefixIcon: Icon(Icons.edit_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Date & Time row
            _SectionLabel(label: 'Дата и время', theme: theme),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('d MMMM', 'ru').format(_selectedDate),
                    onTap: _pickDate,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: _formatTimeOfDay(_selectedTime),
                    onTap: _pickTime,
                    theme: theme,
                    isDark: isDark,
                    accentColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location field
            _SectionLabel(label: 'Место проведения', theme: theme),
            const SizedBox(height: 8),
            TextField(
              controller: _audienceController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Аудитория, кабинет, адрес...',
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: theme.colorScheme.primary, size: 20),
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.taskAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                ),
                child: const Text(
                  'Добавить задачу',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;
  final Color? accentColor;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    required this.isDark,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? theme.colorScheme.primary;
    return Material(
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
