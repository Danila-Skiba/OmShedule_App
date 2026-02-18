/// Тип занятия
enum LessonType {
  lecture,
  lab,
  exam,
  personal,
}

/// Статус занятия
enum LessonStatus {
  active,
  completed,
  cancelled,
  rescheduled,
}

/// Модель занятия 
class Lesson {
  final String id;
  final String subject;
  final LessonType type;
  final String teacher;
  final String room;
  final String building;
  final String timeStart;
  final String timeEnd;
  final int dayOfWeek;
  final String? date;
  final LessonStatus? status;
  final String? groupId;

  const Lesson({
    required this.id,
    required this.subject,
    required this.type,
    required this.teacher,
    required this.room,
    required this.building,
    required this.timeStart,
    required this.timeEnd,
    required this.dayOfWeek,
    this.date,
    this.status,
    this.groupId,
  });

  String get typeLabel {
    switch (type) {
      case LessonType.lecture:
        return 'Лекция';
      case LessonType.lab:
        return 'Лабораторная';
      case LessonType.exam:
        return 'Экзамен';
      case LessonType.personal:
        return 'Личное';
    }
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['lessonOid'] as String,
      subject: json['subject'] as String,
      type: _lessonTypeFromString(json['type'] as String),
      teacher: json['teacher'] as String,
      room: json['room'] as String,
      building: json['building'] as String,
      timeStart: json['timeStart'] as String,
      timeEnd: json['timeEnd'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      date: json['date'] as String?,
      status: json['status'] != null
          ? _lessonStatusFromString(json['status'] as String)
          : null,
      groupId: json['groupId'] as String?,
    );
  }

  static LessonType _lessonTypeFromString(String s) {
    return LessonType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LessonType.lecture,
    );
  }

  static LessonStatus _lessonStatusFromString(String s) {
    return LessonStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LessonStatus.active,
    );
  }
}
