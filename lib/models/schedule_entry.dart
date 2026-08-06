/// Запись справочника расписания: группа, преподаватель или аудитория.
///
/// Источник — JSON-ассеты `assets/data/{groups,persons,auditories}.json`,
/// выгруженные из API ОмГТУ.
class ScheduleEntry {
  /// Идентификатор для эндпоинтов API (`group/{id}`, `person/{id}`, `auditorium/{id}`).
  final String id;

  /// Отображаемое название: «ФИТ-231», «ИВАНОВ И.И.», «8-101».
  final String name;

  /// Уточнение: факультет и форма обучения, кафедра или корпус с типом аудитории.
  final String desc;

  const ScheduleEntry({
    required this.id,
    required this.name,
    required this.desc,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: '${json['id']}',
      name: (json['name'] as String? ?? '').trim(),
      desc: (json['desc'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
      };
}
