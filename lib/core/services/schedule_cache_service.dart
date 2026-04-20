import '../services/schedule_repository.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';
import '../utils/week_service.dart';

/// Ключ кеша: идентификатор фильтра + дата начала недели.
class _CacheKey {
  final String filterKey;
  final DateTime weekStart;

  _CacheKey(this.filterKey, this.weekStart);

  @override
  bool operator ==(Object other) =>
      other is _CacheKey &&
      other.filterKey == filterKey &&
      other.weekStart.year == weekStart.year &&
      other.weekStart.month == weekStart.month &&
      other.weekStart.day == weekStart.day;

  @override
  int get hashCode => Object.hash(filterKey, DateTime(weekStart.year, weekStart.month, weekStart.day));

  @override
  String toString() => 'CacheKey($filterKey, ${weekStart.toIso8601String()})';
}

/// Запись кеша с данными и временем создания.
class _CacheEntry {
  final List<Lesson> lessons;
  final DateTime createdAt;

  _CacheEntry(this.lessons) : createdAt = DateTime.now();

  /// Кеш актуален в течение 30 минут.
  bool get isValid =>
      DateTime.now().difference(createdAt).inMinutes < 30;
}

/// Сервис кеширования расписания.
/// Хранит данные в памяти с TTL 30 минут.
/// Поддерживает предзагрузку на N недель вперёд.
class ScheduleCacheService {
  ScheduleCacheService._();
  static final ScheduleCacheService instance = ScheduleCacheService._();

  final Map<_CacheKey, _CacheEntry> _cache = {};

  /// Активные запросы — исключают дублирование параллельных загрузок.
  final Map<_CacheKey, Future<ScheduleLoadResult>> _inflight = {};

  // ---------------------------------------------------------------------------
  // Публичный API
  // ---------------------------------------------------------------------------

  /// Строит строковый ключ фильтра по текущим параметрам.
  static String filterKey({
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) {
    if (groupIds != null) return 'group:$groupIds';
    if (teacherNames != null) return 'teacher:$teacherNames';
    if (roomIds != null) return 'room:$roomIds';
    return 'none';
  }

  /// Получить расписание: сначала из кеша, иначе — из репозитория.
  Future<ScheduleLoadResult> get(
    ScheduleRepository repository,
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) {
    final fKey = filterKey(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
    final key = _CacheKey(fKey, period.startDate);

    // Есть валидный кеш — отдаём сразу.
    final cached = _cache[key];
    if (cached != null && cached.isValid) {
      return Future.value(ScheduleLoadResult(lessons: cached.lessons));
    }

    // Уже идёт запрос для этого ключа — подключаемся к нему.
    final existing = _inflight[key];
    if (existing != null) return existing;

    // Новый запрос.
    final future = _fetch(repository, period,
        groupIds: groupIds, teacherNames: teacherNames, roomIds: roomIds,
        key: key);
    _inflight[key] = future;
    return future;
  }

  /// Предзагрузка следующих [weeksAhead] недель начиная с [fromWeek].
  /// Запускается в фоне, не блокирует UI.
  void prefetch(
    ScheduleRepository repository,
    WeekPeriod fromWeek, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
    int weeksAhead = 2,
  }) {
    WeekPeriod week = fromWeek;
    for (var i = 0; i < weeksAhead; i++) {
      week = WeekService.getNextWeek(week);
      final fKey = filterKey(
        groupIds: groupIds,
        teacherNames: teacherNames,
        roomIds: roomIds,
      );
      final key = _CacheKey(fKey, week.startDate);

      // Пропускаем если уже есть валидный кеш или идёт загрузка.
      final cached = _cache[key];
      if (cached != null && cached.isValid) continue;
      if (_inflight.containsKey(key)) continue;

      final capturedWeek = week;
      final future = _fetch(
        repository,
        capturedWeek,
        groupIds: groupIds,
        teacherNames: teacherNames,
        roomIds: roomIds,
        key: key,
      );
      _inflight[key] = future;
    }
  }

  /// Получить закешированные уроки без сетевого запроса (для соседних страниц PageView).
  List<Lesson>? getCachedLessons(
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) {
    final fKey = filterKey(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
    final key = _CacheKey(fKey, period.startDate);
    final cached = _cache[key];
    return (cached != null && cached.isValid) ? cached.lessons : null;
  }

  /// Инвалидировать кеш для конкретного фильтра (при смене группы/препода).
  void invalidateFilter({
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) {
    final fKey = filterKey(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );
    _cache.removeWhere((k, _) => k.filterKey == fKey);
    _inflight.removeWhere((k, _) => k.filterKey == fKey);
  }

  /// Полная очистка кеша.
  void clear() {
    _cache.clear();
    _inflight.clear();
  }

  // ---------------------------------------------------------------------------
  // Внутренние методы
  // ---------------------------------------------------------------------------

  Future<ScheduleLoadResult> _fetch(
    ScheduleRepository repository,
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
    required _CacheKey key,
  }) async {
    try {
      final result = await repository.loadFromApi(
        period,
        groupIds: groupIds,
        teacherNames: teacherNames,
        roomIds: roomIds,
      );
      if (!result.hasError) {
        _cache[key] = _CacheEntry(result.lessons);
      }
      return result;
    } finally {
      _inflight.remove(key);
    }
  }
}
