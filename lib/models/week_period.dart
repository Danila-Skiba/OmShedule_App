/// Модель периода недели для расписания.
/// Неделя считается с понедельника по воскресенье.
class WeekPeriod {
  /// Дата начала недели (понедельник, время 00:00)
  final DateTime startDate;

  /// Дата конца недели (воскресенье, время 23:59)
  final DateTime endDate;

  /// Отформатированная строка периода для отображения 
  final String formattedPeriod;

  /// Список из 7 дат: [Пн, Вт, Ср, Чт, Пт, Сб, Вс]
  final List<DateTime> dates;

  const WeekPeriod({
    required this.startDate,
    required this.endDate,
    required this.formattedPeriod,
    required this.dates,
  });

  /// Проверяет, входит ли дата в этот период недели.
  bool contains(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// Индекс дня недели (0 = Пн, 6 = Вс) для данной даты, если она в периоде.
  int? dayIndexFor(DateTime date) {
    if (!contains(date)) return null;
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (var i = 0; i < dates.length; i++) {
      final d = DateTime(dates[i].year, dates[i].month, dates[i].day);
      if (d == dateOnly) return i;
    }
    return null;
  }
}
