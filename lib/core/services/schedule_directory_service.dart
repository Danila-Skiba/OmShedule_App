import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/directory_updates_store.dart';
import '../../data/schedule_data.dart';
import '../../models/directory_kind.dart';
import '../../models/schedule_entry.dart';
import 'settings_service.dart';

/// Поиск по справочникам вуза.
///
/// `https://rasp.omgtu.ru/api/search?term={строка}&type={group|person|auditorium}`
/// возвращает массив `{id, label, description}`. Отдать «всё сразу» эндпоинт не
/// умеет — только совпадения с поисковой строкой, поэтому справочник
/// обходится набором терминов (см. [ScheduleDirectoryService._termsFor]).
abstract class DirectorySearchApi {
  Future<List<ScheduleEntry>> search(String term, DirectoryKind kind);
}

class DirectorySearchApiClient implements DirectorySearchApi {
  /// Тот же таймаут, что и у расписания: без него «повисший» ответ держал бы
  /// обновление до бесконечности.
  static const Duration _requestTimeout = Duration(seconds: 20);

  final String baseUrl;
  final http.Client client;

  DirectorySearchApiClient({
    this.baseUrl = 'https://rasp.omgtu.ru/api/search',
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  Future<List<ScheduleEntry>> search(String term, DirectoryKind kind) async {
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {'term': term, 'type': kind.apiType},
    );

    final response = await client.get(url, headers: {
      'Accept': 'application/json',
    }).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('search ${kind.apiType} «$term»: '
          'статус ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => ScheduleEntry(
            id: '${e['id']}',
            // В поиске поля называются иначе, чем в наших JSON-справочниках.
            name: (e['label'] as String? ?? '').trim(),
            desc: (e['description'] as String? ?? '').trim(),
          ),
        )
        .where((e) => e.name.isNotEmpty && e.id.isNotEmpty && e.id != 'null')
        .toList();
  }
}

/// Итог обновления справочников.
class DirectoryUpdateResult {
  /// Сколько записей добавилось по каждому справочнику.
  final Map<DirectoryKind, int> added;

  /// Справочники, которые не удалось обновить (сеть, разбор ответа).
  final Map<DirectoryKind, String> errors;

  const DirectoryUpdateResult({
    this.added = const {},
    this.errors = const {},
  });

  int get addedTotal => added.values.fold(0, (sum, n) => sum + n);

  bool get hasErrors => errors.isNotEmpty;

  /// Ничего не обновлялось: сроки ещё не наступили.
  bool get isEmpty => added.isEmpty && errors.isEmpty;
}

/// Обновление справочников групп, преподавателей и аудиторий силами клиента.
///
/// Раньше это делалось ноутбуком `update_data.ipynb` в соседнем репозитории, а
/// в приложение справочники попадали ассетами при сборке: между выгрузками
/// новые группы и преподаватели были приложению не видны. Теперь их дотягивает
/// сам клиент.
///
/// Cron на iOS нет, поэтому работает та же схема, что у новостей: при запуске
/// приложения проверяется, наступил ли срок, и обновление идёт фоном. Сроки
/// разные (см. [isDue]) — справочники меняются с очень разной скоростью.
///
/// Скачанное не переписывает ассеты (они внутри бандла и доступны только на
/// чтение), а ложится отдельным файлом-добавкой в documents dir; при загрузке
/// [ScheduleData] накладывает её поверх ассетов.
class ScheduleDirectoryService {
  ScheduleDirectoryService._();

  static final ScheduleDirectoryService instance = ScheduleDirectoryService._();

  /// Подменяется в тестах.
  @visibleForTesting
  DirectorySearchApi api = DirectorySearchApiClient();

  /// Пауза между запросами: обход по кафедрам — это несколько десятков
  /// запросов подряд, и выпускать их в API вуза очередью без передышки
  /// невежливо.
  static const Duration _throttle = Duration(milliseconds: 200);

  /// Сколько запросов подряд должно провалиться, чтобы бросить обход.
  static const int _failuresBeforeGivingUp = 3;

  /// Идёт ли обновление прямо сейчас — при старте его дёргает `main`, а с
  /// экрана настроек может дёрнуть пользователь.
  Future<DirectoryUpdateResult>? _inFlight;

  bool get isRunning => _inFlight != null;

  // ---------------------------------------------------------------------------
  // Сроки
  // ---------------------------------------------------------------------------

  /// Раз в год — аудитории: корпуса и их нумерация почти не меняются.
  static const Duration _yearly = Duration(days: 365);

  /// Раз в полгода — базовый срок для групп.
  static const Duration _halfYear = Duration(days: 182);

  /// Раз в неделю — учащённый срок для групп в период набора.
  static const Duration _weekly = Duration(days: 7);

  /// Период, когда группы первого курса появляются в API вуза порциями:
  /// с 1 августа по 30 сентября включительно. Пока он идёт, полугодового
  /// срока мало — иначе первокурсник не найдёт свою группу до зимы.
  static bool _isAdmissionSeason(DateTime now) =>
      now.month == DateTime.august || now.month == DateTime.september;

  /// Пора ли обновлять справочник [kind].
  ///
  /// Вынесено отдельной чистой функцией, чтобы правила проверялись тестами, а
  /// не только наблюдением за приложением.
  ///
  /// - преподаватели — раз в календарный месяц. Точную дату «1-е число»
  ///   клиент выдержать не может (фоновых задач по расписанию на iOS нет),
  ///   поэтому обновление случается при первом за месяц запуске;
  /// - группы — раз в полгода, а с августа по сентябрь дополнительно раз
  ///   в неделю;
  /// - аудитории — раз в год.
  @visibleForTesting
  static bool isDue(
    DirectoryKind kind, {
    required DateTime? lastRun,
    required DateTime now,
  }) {
    // Справочник ещё ни разу не обновлялся — идём в сеть при первой
    // возможности, каким бы ни был срок.
    if (lastRun == null) return true;

    // Часы устройства могли перевести назад: срок «в будущем» иначе
    // заморозил бы обновления до тех пор, пока время не догонит метку.
    if (lastRun.isAfter(now)) return true;

    final elapsed = now.difference(lastRun);

    return switch (kind) {
      DirectoryKind.persons =>
        lastRun.year != now.year || lastRun.month != now.month,
      DirectoryKind.groups => _isAdmissionSeason(now)
          ? elapsed >= _weekly
          : elapsed >= _halfYear,
      DirectoryKind.auditoriums => elapsed >= _yearly,
    };
  }

  /// Время последнего успешного обновления справочника.
  DateTime? lastRunFor(DirectoryKind kind) =>
      SettingsService.getDirectoryUpdatedAt(kind.storageKey);

  /// Самое старое из времён обновления — для строки «Обновлено …» в настройках.
  DateTime? get lastRunAny {
    final dates = DirectoryKind.values
        .map(lastRunFor)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  // ---------------------------------------------------------------------------
  // Обновление
  // ---------------------------------------------------------------------------

  /// Обновляет те справочники, у которых наступил срок.
  ///
  /// При первом запуске на устройстве меток нет — значит проходят все три
  /// справочника, и дальше сроки отсчитываются от этого дня. Дата установки
  /// приложения к выгрузке ассетов отношения не имеет, так что «раз в месяц»
  /// у каждого пользователя своё — зато не нужен ни сервер, ни фоновый cron,
  /// которого на iOS всё равно нет.
  Future<DirectoryUpdateResult> refreshIfDue() {
    // Дёрнуть могут дважды (старт и возврат из фона) — второй вызов
    // присоединяется к первому, а не открывает свою очередь запросов.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _refresh();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<DirectoryUpdateResult> _refresh() async {
    final now = DateTime.now();
    final due = DirectoryKind.values
        .where((kind) => isDue(kind, lastRun: lastRunFor(kind), now: now))
        .toList();

    if (due.isEmpty) return const DirectoryUpdateResult();

    final stored = Map<DirectoryKind, List<ScheduleEntry>>.from(
      await DirectoryUpdatesStore.read(),
    );
    final added = <DirectoryKind, int>{};
    final errors = <DirectoryKind, String>{};
    var changed = false;

    for (final kind in due) {
      try {
        final fresh = await _fetchNew(kind);
        if (fresh.isNotEmpty) {
          stored[kind] = [...?stored[kind], ...fresh];
          ScheduleData.addEntries(kind, fresh);
          changed = true;
        }
        added[kind] = fresh.length;
        // Метку ставим и при нулевом улове: справочник проверен, значит срок
        // отсчитывается заново. Иначе каждый запуск ходил бы в сеть впустую.
        SettingsService.setDirectoryUpdatedAt(kind.storageKey, DateTime.now());
      } catch (e) {
        debugPrint('Справочник «${kind.title}» не обновлён: $e');
        errors[kind] = e.toString();
      }
    }

    if (changed) await DirectoryUpdatesStore.write(stored);

    return DirectoryUpdateResult(added: added, errors: errors);
  }

  /// Забирает из API записи справочника, которых ещё нет.
  Future<List<ScheduleEntry>> _fetchNew(DirectoryKind kind) async {
    final terms = _termsFor(kind);
    if (terms.isEmpty) return const [];

    final knownIds = ScheduleData.idsFor(kind);
    final fresh = <String, ScheduleEntry>{};
    Object? lastError;
    var failed = 0;
    var failedInARow = 0;

    for (final term in terms) {
      try {
        final found = await api.search(term, kind);
        failedInARow = 0;
        for (final entry in found) {
          if (knownIds.contains(entry.id)) continue;
          if (!_isAcceptable(entry, kind)) continue;
          // Термины перекрываются (одна и та же запись находится по разным
          // строкам поиска) — ключ по id разводит дубли ещё до сохранения.
          fresh[entry.id] = entry;
        }
      } catch (e) {
        lastError = e;
        failed++;
        failedInARow++;
        // Связи, судя по всему, нет вовсе. Продолжать бессмысленно и дорого:
        // у преподавателей терминов несколько десятков, и каждый неудачный
        // запрос при «висящей» сети упирается в двадцатисекундный таймаут —
        // фоновое обновление растянулось бы на много минут.
        if (failedInARow >= _failuresBeforeGivingUp) break;
      }
      await Future<void>.delayed(_throttle);
    }

    // Часть терминов может не отработать (сеть моргнула) — это не повод терять
    // найденное. А вот если не удалось ничего, обновление считается неудачным:
    // иначе мы поставим метку и не вернёмся сюда до конца срока.
    if (fresh.isEmpty && failed > 0 && lastError != null) {
      throw Exception('запросы не выполнены ($failed из ${terms.length}): '
          '$lastError');
    }

    return fresh.values.toList();
  }

  /// Строки поиска для обхода справочника.
  List<String> _termsFor(DirectoryKind kind) {
    switch (kind) {
      case DirectoryKind.groups:
        // Название группы содержит две последние цифры года поступления:
        // «МО-261» — набор 2026-го. Новые группы ищем именно по ним.
        return [_admissionYearDigits(DateTime.now())];

      case DirectoryKind.persons:
        // Поиск умеет искать и по описанию — этим пользовался ещё ноутбук
        // (термины вида «Прикладная математика и фундаментальная
        // информатика»). Список кафедр берём из самого справочника, чтобы он
        // не расходился с реальностью и не жил отдельной константой в коде.
        return ScheduleData.persons
            .map((e) => e.desc.trim())
            .where((desc) => desc.length > 4)
            .toSet()
            .toList()
          ..sort();

      case DirectoryKind.auditoriums:
        // Корпуса из описаний вида «8-101 | УЛК-8 | Учебная лаборатория».
        // Список сам собой ограничен теми корпусами, которые приложение
        // показывает (УЛК и Главный корпус), — искать остальные незачем.
        return ScheduleData.auditoriums
            .map(_buildingOf)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    }
  }

  /// Две последние цифры года набора: для 2026-го — «26».
  static String _admissionYearDigits(DateTime now) =>
      (now.year % 100).toString().padLeft(2, '0');

  /// Годится ли найденная запись для справочника.
  bool _isAcceptable(ScheduleEntry entry, DirectoryKind kind) {
    switch (kind) {
      case DirectoryKind.groups:
        // Поиск по «26» вернёт и «МО-261» (нужна), и, например, «АТ-226»
        // (набор 2022-го, просто с шестёркой в номере). Оставляем только те,
        // где две цифры после дефиса — это год текущего набора.
        return _admissionYearOf(entry.name) == _admissionYearDigits(DateTime.now());

      case DirectoryKind.persons:
        // «ВАКАНСИЯ» — незанятая ставка, а не преподаватель. Отсеивал ещё
        // ноутбук.
        return !entry.name.toUpperCase().contains('ВАКАНСИЯ');

      case DirectoryKind.auditoriums:
        return ScheduleData.isShownAuditorium(entry);
    }
  }

  /// Год набора из названия группы: «МО-261» → «26», «АСП-251/3» → «25».
  /// Для названий, не подходящих под шаблон, — null.
  static String? _admissionYearOf(String name) {
    final match = RegExp(r'^[^-]+-(\d{2})').firstMatch(name.trim());
    return match?.group(1);
  }

  /// Корпус из описания аудитории (средний сегмент, разделитель «|»).
  static String? _buildingOf(ScheduleEntry entry) {
    final parts = entry.desc.split('|');
    if (parts.length < 2) return null;
    final building = parts[1].trim();
    return building.isEmpty ? null : building;
  }
}
