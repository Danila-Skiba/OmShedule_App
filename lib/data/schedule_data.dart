import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/schedule_entry.dart';

/// Справочники соответствия «название → id» для API ОмГТУ.
///
/// Данные лежат в JSON-ассетах `assets/data/` (выгрузка из API вуза) и
/// загружаются один раз при старте приложения через [load] — до `runApp`,
/// поэтому дальше доступ к справочникам синхронный.
class ScheduleData {
  ScheduleData._();

  static const _groupsAsset = 'assets/data/groups.json';
  static const _personsAsset = 'assets/data/persons.json';
  static const _auditoriumsAsset = 'assets/data/auditories.json';

  static List<ScheduleEntry> _groups = const [];
  static List<ScheduleEntry> _persons = const [];
  static List<ScheduleEntry> _auditoriums = const [];

  static Map<String, String> _groupIds = const {};
  static Map<String, String> _personIds = const {};
  static Map<String, String> _auditoriumIds = const {};

  static bool _loaded = false;

  /// Справочники загружены (хотя бы частично).
  static bool get isLoaded => _loaded;

  /// Читает справочники из ассетов. Повторные вызовы игнорируются.
  static Future<void> load() async {
    if (_loaded) return;

    _groups = await _loadAsset(_groupsAsset);
    _persons = await _loadAsset(_personsAsset);
    _auditoriums = await _loadAsset(_auditoriumsAsset);

    _groupIds = _buildIndex(_groups);
    _personIds = _buildIndex(_persons);
    _auditoriumIds = _buildIndex(_auditoriums);

    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Списки с описаниями (для экранов выбора)
  // ---------------------------------------------------------------------------

  static List<ScheduleEntry> get groups => _groups;

  static List<ScheduleEntry> get persons => _persons;

  static List<ScheduleEntry> get auditoriums => _auditoriums;

  // ---------------------------------------------------------------------------
  // Карты «название → id» (для запросов в API)
  // ---------------------------------------------------------------------------

  static Map<String, String> get getgroups => _groupIds;

  static Map<String, String> get getpersons => _personIds;

  static Map<String, String> get getauditorium => _auditoriumIds;

  /// Первое название из справочника групп (значение по умолчанию).
  static String? get firstGroupName =>
      _groups.isEmpty ? null : _groups.first.name;

  /// Первое название из справочника преподавателей (значение по умолчанию).
  static String? get firstPersonName =>
      _persons.isEmpty ? null : _persons.first.name;

  /// Есть ли такая группа в справочнике (сохранённый фильтр мог устареть).
  static bool hasGroup(String? name) =>
      name != null && _groupIds.containsKey(name);

  static bool hasPerson(String? name) =>
      name != null && _personIds.containsKey(name);

  static bool hasAuditorium(String? name) =>
      name != null && _auditoriumIds.containsKey(name);

  // ---------------------------------------------------------------------------
  // Внутреннее
  // ---------------------------------------------------------------------------

  /// Разбирает JSON-массив записей справочника и сортирует его по названию.
  static Future<List<ScheduleEntry>> _loadAsset(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return entries;
    } catch (e) {
      debugPrint('Не удалось загрузить справочник $asset: $e');
      return const [];
    }
  }

  /// «Название → id». При дублях названий побеждает первая запись.
  static Map<String, String> _buildIndex(List<ScheduleEntry> entries) {
    final map = <String, String>{};
    for (final entry in entries) {
      map.putIfAbsent(entry.name, () => entry.id);
    }
    return Map.unmodifiable(map);
  }
}
