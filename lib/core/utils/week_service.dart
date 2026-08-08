import '../../models/week_period.dart';

/// Сервис для работы с неделями расписания.
/// Неделя: понедельник (1) — воскресенье (7).
/// Все даты нормализованы в local timezone (без времени для сравнений).
class WeekService {
  WeekService._();

  /// Сокращения дней недели: Пн, Вт, Ср, Чт, Пт, Сб, Вс
  static const weekDayLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  /// Возвращает понедельник недели для указанной даты.
  /// Входная дата может быть любой — берётся понедельник той недели.
  static DateTime _getMondayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // weekday: 1 = Mon, 7 = Sun. Offset от понедельника.
    final offset = d.weekday - 1;
    return d.subtract(Duration(days: offset));
  }

  /// Создаёт WeekPeriod для недели, в которую входит указанная дата.
  static WeekPeriod getWeekForDate(DateTime date) {
    final monday = _getMondayOfWeek(date);
    final sunday = monday.add(const Duration(days: 6));
    final dates = List.generate(7, (i) => monday.add(Duration(days: i)));
    final formatted = _formatPeriod(monday, sunday);
    return WeekPeriod(
      startDate: monday,
      endDate: sunday,
      formattedPeriod: formatted,
      dates: dates,
    );
  }

  /// Следующая неделя (понедельник + 7 дней).
  static WeekPeriod getNextWeek(WeekPeriod period) {
    final nextMonday = period.startDate.add(const Duration(days: 7));
    return getWeekForDate(nextMonday);
  }

  /// Предыдущая неделя (понедельник - 7 дней).
  static WeekPeriod getPreviousWeek(WeekPeriod period) {
    final prevMonday = period.startDate.subtract(const Duration(days: 7));
    return getWeekForDate(prevMonday);
  }

  /// Форматирование периода для отображения.
  /// Учитывает переход между месяцами/годами.
  static String _formatPeriod(DateTime start, DateTime end) {
    if (start.month == end.month && start.year == end.year) {
      return '${start.day} - ${end.day} ${_monthName(start)}';
    }
    if (start.year == end.year) {
      return '${start.day} ${_monthNameShort(start)} - ${end.day} ${_monthName(end)}';
    }
    return '${start.day} ${_monthNameShort(start)} ${start.year} - ${end.day} ${_monthName(end)} ${end.year}';
  }

  static String _monthName(DateTime d) {
    const names = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return names[d.month - 1];
  }

  static String _monthNameShort(DateTime d) {
    const names = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return names[d.month - 1];
  }

  /// Проверка валидности даты (защита от некорректных дат, например 31 февраля).
  static bool isValidDate(DateTime date) {
    if (date.year < 2000 || date.year > 2100) return false;
    if (date.month < 1 || date.month > 12) return false;
    if (date.day < 1 || date.day > 31) return false;
    try {
      DateTime(date.year, date.month, date.day);
      return true;
    } catch (_) {
      return false;
    }
  }
}
