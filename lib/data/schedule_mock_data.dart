import '../models/lesson.dart';

/// Период расписания: 17–24 февраля (неделя, ПН=1 … СБ=6)
class ScheduleMockData {
  ScheduleMockData._();

  /// Группы для выбора
  static const List<String> groupIds = ['МО-231', 'ИВТ-231'];

  /// Преподаватели для выбора (id используется для фильтра по имени)
  static const List<String> teacherNames = ['Иванов И.И.', 'Петров П.П.'];

  /// Аудитории для выбора
  static const List<String> roomIds = ['301', '405'];

  /// Все занятия для расписания (по группам, преподавателям, аудиториям).
  /// Неделя 17–24 фев: dayOfWeek 1 = ПН, 6 = СБ.
  static final List<Lesson> allLessons = [
    // МО-231
    ..._lessonsForGroup('МО-231', 'Иванов И.И.', 'Петров П.П.'),
    // ИВТ-231
    ..._lessonsForGroup('ИВТ-231', 'Петров П.П.', 'Иванов И.И.'),
  ];

  static List<Lesson> _lessonsForGroup(String groupId, String teacher1, String teacher2) {
    const b = 'Корпус 1';
    return [
      Lesson(id: '${groupId}_1', subject: 'Математический анализ', type: LessonType.lecture, teacher: teacher1, room: '301', building: b, timeStart: '08:30', timeEnd: '10:15', dayOfWeek: 1, groupId: groupId),
      Lesson(id: '${groupId}_2', subject: 'Физика', type: LessonType.lecture, teacher: teacher2, room: '405', building: b, timeStart: '10:30', timeEnd: '12:15', dayOfWeek: 1, groupId: groupId),
      Lesson(id: '${groupId}_3', subject: 'Программирование', type: LessonType.lab, teacher: teacher1, room: '301', building: b, timeStart: '14:00', timeEnd: '15:45', dayOfWeek: 1, groupId: groupId),
      Lesson(id: '${groupId}_4', subject: 'Английский язык', type: LessonType.lecture, teacher: teacher2, room: '405', building: b, timeStart: '08:30', timeEnd: '10:15', dayOfWeek: 2, groupId: groupId),
      Lesson(id: '${groupId}_5', subject: 'Базы данных', type: LessonType.lab, teacher: teacher1, room: '301', building: b, timeStart: '11:00', timeEnd: '12:45', dayOfWeek: 2, groupId: groupId),
      Lesson(id: '${groupId}_6', subject: 'Дискретная математика', type: LessonType.lecture, teacher: teacher2, room: '405', building: b, timeStart: '08:30', timeEnd: '10:15', dayOfWeek: 3, groupId: groupId),
      Lesson(id: '${groupId}_7', subject: 'Информатика', type: LessonType.lecture, teacher: teacher1, room: '301', building: b, timeStart: '11:00', timeEnd: '12:45', dayOfWeek: 3, groupId: groupId),
      Lesson(id: '${groupId}_8', subject: 'Физкультура', type: LessonType.lecture, teacher: teacher2, room: '405', building: b, timeStart: '14:00', timeEnd: '15:45', dayOfWeek: 4, groupId: groupId),
      Lesson(id: '${groupId}_9', subject: 'Экономика', type: LessonType.lecture, teacher: teacher1, room: '301', building: b, timeStart: '08:30', timeEnd: '10:15', dayOfWeek: 5, groupId: groupId),
    ];
  }

  /// Занятия по выбранной группе
  static List<Lesson> lessonsForGroup(String? groupId) {
    if (groupId == null || groupId.isEmpty) return [];
    return allLessons.where((l) => l.groupId == groupId).toList();
  }

  /// Занятия по выбранному преподавателю
  static List<Lesson> lessonsForTeacher(String? teacherName) {
    if (teacherName == null || teacherName.isEmpty) return [];
    return allLessons.where((l) => l.teacher == teacherName).toList();
  }

  /// Занятия по выбранной аудитории
  static List<Lesson> lessonsForRoom(String? roomId) {
    if (roomId == null || roomId.isEmpty) return [];
    return allLessons.where((l) => l.room == roomId).toList();
  }

  /// Занятия по нескольким группам
  static List<Lesson> lessonsForGroups(Set<String> ids) {
    if (ids.isEmpty) return [];
    return allLessons.where((l) => l.groupId != null && ids.contains(l.groupId)).toList();
  }

  /// Занятия по нескольким преподавателям
  static List<Lesson> lessonsForTeachers(Set<String> names) {
    if (names.isEmpty) return [];
    return allLessons.where((l) => names.contains(l.teacher)).toList();
  }

  /// Занятия по нескольким аудиториям
  static List<Lesson> lessonsForRooms(Set<String> ids) {
    if (ids.isEmpty) return [];
    return allLessons.where((l) => ids.contains(l.room)).toList();
  }

  /// Фильтрация по ОДНОМУ типу (исключающая).
  /// Приоритет: groupIds > teacherNames > roomIds.
  /// Не суммирует расписание по разным фильтрам.
  static List<Lesson> lessonsFilteredExclusive({
    Set<String>? groupIds,
    Set<String>? teacherNames,
    Set<String>? roomIds,
  }) {
    List<Lesson> list;
    if (groupIds != null && groupIds.isNotEmpty) {
      list = lessonsForGroups(groupIds);
    } else if (teacherNames != null && teacherNames.isNotEmpty) {
      list = lessonsForTeachers(teacherNames);
    } else if (roomIds != null && roomIds.isNotEmpty) {
      list = lessonsForRooms(roomIds);
    } else {
      list = [];
    }
    return list
      ..sort((a, b) => a.dayOfWeek != b.dayOfWeek
          ? a.dayOfWeek.compareTo(b.dayOfWeek)
          : a.timeStart.compareTo(b.timeStart));
  }

  /// Устаревший метод (объединение). Оставлен для совместимости.
  @Deprecated('Используйте lessonsFilteredExclusive для независимых фильтров')
  static List<Lesson> lessonsFiltered({
    Set<String>? groupIds,
    Set<String>? teacherNames,
    Set<String>? roomIds,
  }) => lessonsFilteredExclusive(
        groupIds: groupIds,
        teacherNames: teacherNames,
        roomIds: roomIds,
      );
}
