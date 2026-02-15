/// Тип расписания: группа, преподаватель или аудитория
enum ScheduleType {
  group,
  teacher,
  audience,
}

extension ScheduleTypeX on ScheduleType {
  String get label {
    switch (this) {
      case ScheduleType.group:
        return 'Группа';
      case ScheduleType.teacher:
        return 'Преподаватель';
      case ScheduleType.audience:
        return 'Аудитория';
    }
  }
}
