import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/directory_kind.dart';
import '../models/schedule_entry.dart';

/// Записи справочников, которые приложение дотянуло из API вуза само.
///
/// Ассеты `assets/data/*.json` лежат в бандле и доступны только на чтение,
/// поэтому скачанное хранится отдельным файлом в documents dir, а при загрузке
/// накладывается поверх ассетов ([ScheduleData.load]). Файл содержит **только
/// добавленное** — так очередная сборка приложения со свежими ассетами не
/// конфликтует с накопленным на устройстве: совпадения отсеются по id.
class DirectoryUpdatesStore {
  DirectoryUpdatesStore._();

  static const String fileName = 'directory_updates.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Сохранённые добавки по справочникам. Пустая карта — файла ещё нет.
  static Future<Map<DirectoryKind, List<ScheduleEntry>>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const {};

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return const {};

      final result = <DirectoryKind, List<ScheduleEntry>>{};
      for (final kind in DirectoryKind.values) {
        final raw = decoded[kind.storageKey];
        if (raw is! List) continue;
        result[kind] = raw
            .whereType<Map<String, dynamic>>()
            .map(ScheduleEntry.fromJson)
            .where((e) => e.name.isNotEmpty)
            .toList();
      }
      return result;
    } catch (e) {
      debugPrint('Добавки к справочникам не прочитаны: $e');
      return const {};
    }
  }

  /// Перезаписывает файл добавок целиком.
  static Future<void> write(
    Map<DirectoryKind, List<ScheduleEntry>> data,
  ) async {
    try {
      final file = await _file();
      final encoded = <String, dynamic>{
        for (final entry in data.entries)
          entry.key.storageKey:
              entry.value.map((e) => e.toJson()).toList(growable: false),
      };
      await file.writeAsString(jsonEncode(encoded), flush: true);
    } catch (e) {
      debugPrint('Добавки к справочникам не сохранены: $e');
    }
  }
}
