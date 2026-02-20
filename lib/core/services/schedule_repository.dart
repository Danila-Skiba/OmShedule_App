import '../../data/schedule_mock_data.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';

/// Результат загрузки расписания.
/// В будущем здесь будут реальные данные из API.
class ScheduleLoadResult {
  final List<Lesson> lessons;
  final String? error;

  const ScheduleLoadResult({required this.lessons, this.error});

  bool get hasError => error != null;
}

/// Репозиторий расписания. Готов к интеграции с API.
/// Сейчас использует моковые данные. При интеграции с API:
/// - заменить _loadFromApi на реальный запрос;
/// - обрабатывать сетевые ошибки;
/// - добавить кеширование при необходимости.
abstract class ScheduleRepository {
  /// Загружает расписание на указанный период недели.
  /// [period] — период недели (Пн–Вс).
  /// [groupIds], [teacherNames], [roomIds] — фильтры (как в текущем UI).
  Future<ScheduleLoadResult> loadScheduleForWeek(
    WeekPeriod period, {
    Set<String>? groupIds,
    Set<String>? teacherNames,
    Set<String>? roomIds,
  });
}

/// Реализация с моковыми данными.
/// TODO: заменить на ScheduleApiRepository при подключении API.
class ScheduleRepositoryImpl implements ScheduleRepository {
  @override
  Future<ScheduleLoadResult> loadScheduleForWeek(
    WeekPeriod period, {
    Set<String>? groupIds,
    Set<String>? teacherNames,
    Set<String>? roomIds,
  }) async {
    // Имитация задержки сети при переключении недели
    await Future<void>.delayed(const Duration(milliseconds: 300));

    try {
      // Моковые данные: расписание не привязано к датам, используем dayOfWeek (1–6).
      // В реальном API здесь будет запрос, например:
      // final response = await http.get(Uri.parse('$baseUrl/schedule?from=${period.startDate}&to=${period.endDate}&...'));
      final lessons = ScheduleMockData.lessonsFiltered(
        groupIds: groupIds,
        teacherNames: teacherNames,
        roomIds: roomIds,
      );
      return ScheduleLoadResult(lessons: lessons);
    } catch (e) {
      return ScheduleLoadResult(
        lessons: [],
        error: 'Не удалось загрузить расписание: $e',
      );
    }
  }
}
