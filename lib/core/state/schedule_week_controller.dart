import 'package:flutter/foundation.dart';

import '../services/schedule_repository.dart';
import '../services/schedule_cache_service.dart';
import '../utils/week_service.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';

/// Состояние загрузки расписания.
enum ScheduleLoadState { idle, loading, success, error }

/// Контроллер состояния недели и расписания.
/// Принимает начальные фильтры, чтобы избежать двойной загрузки.
class ScheduleWeekController extends ChangeNotifier {
  ScheduleWeekController({
    ScheduleRepository? repository,
    DateTime? initialDate,
    String? initialGroupIds,
    String? initialTeacherNames,
    String? initialRoomIds,
  })  : _repository = repository ?? ApiClient(),
        _selectedDate = initialDate ?? DateTime.now(),
        _currentWeek =
            WeekService.getWeekForDate(initialDate ?? DateTime.now()),
        _groupIds = initialGroupIds,
        _teacherNames = initialTeacherNames,
        _roomIds = initialRoomIds {
    _loadSchedule(prefetchAhead: true);
  }

  final ScheduleRepository _repository;

  DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  WeekPeriod _currentWeek;
  WeekPeriod get currentWeek => _currentWeek;

  List<Lesson> _lessons = [];
  List<Lesson> get lessons => List.unmodifiable(_lessons);

  ScheduleLoadState _loadState = ScheduleLoadState.idle;
  ScheduleLoadState get loadState => _loadState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _groupIds;
  String? _teacherNames;
  String? _roomIds;

  // ---------------------------------------------------------------------------
  // Фильтры
  // ---------------------------------------------------------------------------

  void setFilters({
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  }) {
    final oldKey = ScheduleCacheService.filterKey(
      groupIds: _groupIds,
      teacherNames: _teacherNames,
      roomIds: _roomIds,
    );
    final newKey = ScheduleCacheService.filterKey(
      groupIds: groupIds,
      teacherNames: teacherNames,
      roomIds: roomIds,
    );

    _groupIds = groupIds;
    _teacherNames = teacherNames;
    _roomIds = roomIds;

    _loadSchedule(prefetchAhead: oldKey != newKey);
  }

  // ---------------------------------------------------------------------------
  // Навигация по неделям
  // ---------------------------------------------------------------------------

  void goToNextWeek() {
    _currentWeek = WeekService.getNextWeek(_currentWeek);
    _selectedDate = _currentWeek.startDate;
    _loadSchedule(prefetchAhead: true);
    notifyListeners();
  }

  void goToPreviousWeek() {
    _currentWeek = WeekService.getPreviousWeek(_currentWeek);
    _selectedDate = _currentWeek.startDate;
    _loadSchedule();
    notifyListeners();
  }

  void goToWeekContaining(DateTime date) {
    if (!WeekService.isValidDate(date)) return;
    _selectedDate = date;
    _currentWeek = WeekService.getWeekForDate(date);
    _loadSchedule(prefetchAhead: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Навигация по дням
  // ---------------------------------------------------------------------------

  void selectDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _currentWeek.dates.length) return;
    _selectedDate = _currentWeek.dates[dayIndex];
    notifyListeners();
  }

  int get selectedDayIndex {
    final idx = _currentWeek.dayIndexFor(_selectedDate);
    return idx ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Загрузка
  // ---------------------------------------------------------------------------

  /// Флаг: режим «Личное» (не нужно загружать расписание из API).
  bool _isPersonalMode = false;

  /// Устанавливает режим «Личное» — пропускает загрузку с API.
  void setPersonalMode(bool value) {
    _isPersonalMode = value;
    if (value) {
      _loadState = ScheduleLoadState.success;
      _errorMessage = null;
      _lessons = [];
      notifyListeners();
    }
  }

  Future<void> _loadSchedule({bool prefetchAhead = false}) async {
    // Если режим «Личное» — не загружаем расписание
    if (_isPersonalMode) {
      _loadState = ScheduleLoadState.success;
      _errorMessage = null;
      _lessons = [];
      notifyListeners();
      return;
    }

    // Если ни один фильтр не задан — нечего загружать
    if (_groupIds == null && _teacherNames == null && _roomIds == null) {
      _loadState = ScheduleLoadState.success;
      _errorMessage = null;
      _lessons = [];
      notifyListeners();
      return;
    }

    _loadState = ScheduleLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await ScheduleCacheService.instance.get(
      _repository,
      _currentWeek,
      groupIds: _groupIds,
      teacherNames: _teacherNames,
      roomIds: _roomIds,
    );

    if (result.hasError) {
      _loadState = ScheduleLoadState.error;
      _errorMessage = result.error;
      _lessons = [];
    } else {
      _loadState = ScheduleLoadState.success;
      _lessons = result.lessons;
    }
    notifyListeners();

    if (prefetchAhead && !result.hasError) {
      ScheduleCacheService.instance.prefetch(
        _repository,
        _currentWeek,
        groupIds: _groupIds,
        teacherNames: _teacherNames,
        roomIds: _roomIds,
        weeksAhead: 2,
      );
    }
  }

  Future<void> retryLoad() => _loadSchedule(prefetchAhead: true);
}
