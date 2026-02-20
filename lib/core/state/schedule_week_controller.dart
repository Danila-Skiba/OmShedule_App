import 'package:flutter/foundation.dart';

import '../services/schedule_repository.dart';
import '../utils/week_service.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';

/// Состояние экрана расписания при загрузке данных.
enum ScheduleLoadState {
  idle,
  loading,
  success,
  error,
}

/// Контроллер состояния недели и расписания.
/// Управляет текущей неделей, выбранной датой и загрузкой расписания.
class ScheduleWeekController extends ChangeNotifier {
  ScheduleWeekController({
    ScheduleRepository? repository,
    DateTime? initialDate,
  })  : _repository = repository ?? ScheduleRepositoryImpl(),
        _selectedDate = initialDate ?? DateTime.now(),
        _currentWeek = WeekService.getWeekForDate(initialDate ?? DateTime.now()) {
    _loadSchedule();
  }

  final ScheduleRepository _repository;

  /// Выбранная пользователем дата (при выборе в календаре или переключении недели).
  DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  /// Текущий отображаемый период недели (Пн–Вс).
  WeekPeriod _currentWeek;
  WeekPeriod get currentWeek => _currentWeek;

  /// Расписание на текущую неделю (после загрузки).
  List<Lesson> _lessons = [];
  List<Lesson> get lessons => List.unmodifiable(_lessons);

  /// Состояние загрузки.
  ScheduleLoadState _loadState = ScheduleLoadState.idle;
  ScheduleLoadState get loadState => _loadState;

  /// Текст ошибки при неудачной загрузке.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Фильтры для загрузки расписания.
  Set<String>? _groupIds;
  Set<String>? _teacherNames;
  Set<String>? _roomIds;

  void setFilters({
    Set<String>? groupIds,
    Set<String>? teacherNames,
    Set<String>? roomIds,
  }) {
    _groupIds = groupIds;
    _teacherNames = teacherNames;
    _roomIds = roomIds;
    _loadSchedule();
  }

  /// Переход на следующую неделю.
  void goToNextWeek() {
    _currentWeek = WeekService.getNextWeek(_currentWeek);
    _selectedDate = _currentWeek.startDate;
    _loadSchedule();
    notifyListeners();
  }

  /// Переход на предыдущую неделю.
  void goToPreviousWeek() {
    _currentWeek = WeekService.getPreviousWeek(_currentWeek);
    _selectedDate = _currentWeek.startDate;
    _loadSchedule();
    notifyListeners();
  }

  /// Переход на неделю, в которую входит указанная дата.
  void goToWeekContaining(DateTime date) {
    if (!WeekService.isValidDate(date)) return;
    _selectedDate = date;
    _currentWeek = WeekService.getWeekForDate(date);
    _loadSchedule();
    notifyListeners();
  }

  /// Выбор дня внутри текущей недели (0 = Пн, 6 = Вс).
  void selectDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _currentWeek.dates.length) return;
    _selectedDate = _currentWeek.dates[dayIndex];
    notifyListeners();
  }

  /// Индекс выбранного дня в текущей неделе (0–6).
  int get selectedDayIndex {
    final idx = _currentWeek.dayIndexFor(_selectedDate);
    return idx ?? 0;
  }

  Future<void> _loadSchedule() async {
    _loadState = ScheduleLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.loadScheduleForWeek(
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
  }

  /// Повторная загрузка при ошибке.
  Future<void> retryLoad() => _loadSchedule();
}
