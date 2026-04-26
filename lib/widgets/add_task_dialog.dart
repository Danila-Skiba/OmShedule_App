import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../core/services/task_service.dart';
import '../models/personal_task.dart';
import 'app_snackbar.dart';

/// Форма добавления личной задачи.
/// Поля: название, время (обязательное), аудитория (опционально).
class AddTaskDialog extends StatefulWidget {
  final DateTime forDate;
  final VoidCallback onSaved;

  const AddTaskDialog({
    super.key,
    required this.forDate,
    required this.onSaved,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _audienceController = TextEditingController();
  String? _timeError;

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static final _timeRegex = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  bool _validate() {
    final time = _timeController.text.trim();
    if (time.isEmpty) {
      setState(() => _timeError = 'Введите время');
      return false;
    }
    if (!_timeRegex.hasMatch(time)) {
      setState(() => _timeError = 'Формат: HH:mm');
      return false;
    }
    setState(() => _timeError = null);
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.show(context, message: 'Введите название задачи', icon: Icons.edit_outlined);
      return;
    }
    final task = PersonalTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      time: _timeController.text.trim(),
      audience: _audienceController.text.trim().isNotEmpty
          ? _audienceController.text.trim()
          : null,
      date: _formatDate(widget.forDate),
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await TaskService.instance.saveTask(task);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Ошибка сохранения: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добавить задачу',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Название',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Встреча, задача...',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Время (обязательно)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  hintText: 'HH:mm',
                  errorText: _timeError,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Аудитория (необязательно)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _audienceController,
                decoration: const InputDecoration(
                  hintText: '312',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
