import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/personal_task.dart';

/// Файл хранения задач в директории приложения.
const _fileName = 'personal_tasks.json';

/// Сервис для работы с личными задачами.
/// Сохраняет данные в локальный JSON-файл.
/// Уведомляет слушателей при изменении данных (удаление/сохранение).
class TaskService extends ChangeNotifier {
  TaskService._();
  static final TaskService _instance = TaskService._();
  static TaskService get instance => _instance;

  List<PersonalTask> _cache = [];
  bool _loaded = false;

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Загружает все задачи из JSON. Кеширует результат.
  Future<List<PersonalTask>> _loadAll() async {
    if (_loaded) return List.from(_cache);
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _cache = [];
        _loaded = true;
        return [];
      }
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>? ?? [];
      _cache = list
          .map((e) => PersonalTask.fromJson(e as Map<String, dynamic>))
          .toList();
      _loaded = true;
      return List.from(_cache);
    } catch (e) {
      debugPrint('TaskService: ошибка чтения JSON, создаём пустой список: $e');
      _cache = [];
      _loaded = true;
      try {
        await _saveAll([]);
      } catch (_) {
      }
      return [];
    }
  }

  Future<void> _saveAll(List<PersonalTask> tasks) async {
    try {
      final file = await _getFile();
      final list = tasks.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(list), flush: true);
      _cache = List.from(tasks);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  /// Задачи на указанную дату (yyyy-MM-dd).
  Future<List<PersonalTask>> loadTasksForDate(DateTime date) async {
    final all = await _loadAll();
    final dateStr = _formatDate(date);
    return all.where((t) => t.date == dateStr).toList()..sort(_sortByTime);
  }

  /// Задачи на период [start, end] (включительно).
  Future<List<PersonalTask>> getTasksForPeriod(DateTime start, DateTime end) async {
    final all = await _loadAll();
    final result = <PersonalTask>[];
    var d = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(endDate)) {
      final dateStr = _formatDate(d);
      result.addAll(all.where((t) => t.date == dateStr));
      d = d.add(const Duration(days: 1));
    }
    result.sort(_sortByDateThenTime);
    return result;
  }

  /// Задачи на сегодня и завтра
  Future<List<PersonalTask>> getTodayAndTomorrowTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getTasksForPeriod(today, tomorrow);
  }

  Future<void> saveTask(PersonalTask task) async {
    final all = await _loadAll();
    final idx = all.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      all[idx] = task;
    } else {
      all.add(task);
    }
    await _saveAll(all);
  }

  Future<void> deleteTask(String taskId) async {
    final all = await _loadAll();
    all.removeWhere((t) => t.id == taskId);
    await _saveAll(all);
  }

  /// Пометить задачу как выполненную/невыполненную.
  Future<void> toggleCompleted(String taskId) async {
    final all = await _loadAll();
    final idx = all.indexWhere((t) => t.id == taskId);
    if (idx < 0) return;
    all[idx] = all[idx].copyWith(completed: !all[idx].completed);
    await _saveAll(all);
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static int _sortByTime(PersonalTask a, PersonalTask b) => a.time.compareTo(b.time);
  static int _sortByDateThenTime(PersonalTask a, PersonalTask b) {
    final dc = a.date.compareTo(b.date);
    return dc != 0 ? dc : a.time.compareTo(b.time);
  }

  /// Сбросить кеш
  void invalidateCache() {
    _loaded = false;
  }
}
