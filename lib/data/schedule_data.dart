import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/directory_kind.dart';
import '../models/schedule_entry.dart';
import 'directory_updates_store.dart';

/// Справочники соответствия «название → id» для API ОмГТУ.
///
/// Данные лежат в JSON-ассетах `assets/data/` (выгрузка из API вуза) и
/// загружаются один раз при старте приложения через [load] — до `runApp`,
/// поэтому дальше доступ к справочникам синхронный.
///
/// Поверх ассетов накладывается то, что приложение дотянуло само
/// (`ScheduleDirectoryService` → [DirectoryUpdatesStore]): новые группы и
/// преподаватели появляются в API вуза между релизами.
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

  /// Читает справочники из ассетов и накладывает сохранённые добавки.
  /// Повторные вызовы игнорируются.
  static Future<void> load() async {
    if (_loaded) return;

    _groups = await _loadAsset(_groupsAsset);
    _persons = await _loadAsset(_personsAsset);
    _auditoriums = await _loadAsset(_auditoriumsAsset);

    final stored = await DirectoryUpdatesStore.read();
    for (final kind in DirectoryKind.values) {
      final entries = stored[kind];
      if (entries != null && entries.isNotEmpty) {
        _merge(kind, entries);
      }
    }

    _reindex();
    _loaded = true;
  }

  /// Добавляет записи в справочник уже во время работы приложения —
  /// после успешного обновления из API.
  static void addEntries(DirectoryKind kind, List<ScheduleEntry> entries) {
    if (entries.isEmpty) return;
    _merge(kind, entries);
    _reindex();
  }

  /// Все известные id справочника — по ним обновление отсеивает уже
  /// имеющиеся записи.
  static Set<String> idsFor(DirectoryKind kind) =>
      entriesFor(kind).map((e) => e.id).toSet();

  static List<ScheduleEntry> entriesFor(DirectoryKind kind) => switch (kind) {
        DirectoryKind.groups => _groups,
        DirectoryKind.persons => _persons,
        DirectoryKind.auditoriums => _auditoriums,
      };

  /// Показываем только учебные корпуса вуза: УЛК и Главный корпус, и только
  /// настоящие аудитории.
  ///
  /// В API вуза висят ещё виртуальные аудитории, базовые кафедры на
  /// предприятиях и площадки партнёров («ООО Красавчик», «ТЭЦ-5», «TestZ») —
  /// выбирать их в фильтре расписания незачем. Отдельно отсекаются
  /// «Неаудиторные»: это не помещение, а пометка вида работы, и расписание по
  /// ней не строится. В снимке `assets/data/auditories.json` таких записей
  /// сейчас нет, но они появляются в выдаче поиска.
  ///
  /// Правило применяется и к ассету, и ко всему, что дотягивается обновлением:
  /// если снимок справочника снова окажется полным, лишнее в списки не попадёт.
  static bool isShownAuditorium(ScheduleEntry entry) {
    if (entry.desc.toLowerCase().contains('неаудиторн')) return false;
    return entry.desc.contains('УЛК') || entry.desc.contains('Главный корпус');
  }

  /// Дописывает записи в справочник, отбрасывая дубли по id и то, что не
  /// проходит отбор. Индексы после этого нужно перестроить ([_reindex]).
  static void _merge(DirectoryKind kind, List<ScheduleEntry> entries) {
    final current = entriesFor(kind);
    final knownIds = current.map((e) => e.id).toSet();

    final accepted = entries.where((e) {
      if (e.name.isEmpty) return false;
      if (!knownIds.add(e.id)) return false;
      if (kind == DirectoryKind.auditoriums && !isShownAuditorium(e)) {
        return false;
      }
      return true;
    });

    final merged = [...current, ...accepted]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    switch (kind) {
      case DirectoryKind.groups:
        _groups = merged;
      case DirectoryKind.persons:
        _persons = merged;
      case DirectoryKind.auditoriums:
        _auditoriums = merged;
    }
  }

  static void _reindex() {
    _groupIds = _buildIndex(_groups);
    _personIds = _buildIndex(_persons);
    _auditoriumIds = _buildIndex(_auditoriums);
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
