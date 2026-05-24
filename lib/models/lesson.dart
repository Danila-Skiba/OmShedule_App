/// Тип занятия
enum LessonType {
  lecture,
  lab,
  practice,
  personal,
  retake,
  exam,
  examPrep,
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
  final String subject;
  final LessonType type;
  final String? teacher;
  final String? room;
  final String? building;
  final String timeStart;
  final String timeEnd;
  final int dayOfWeek;
  final String? date;
  final String? subgroup;
  final int duration; 
  // final LessonStatus? status;
  // final String? groupId;
  final String? group;
  final String? stream;
  // final String? group;

  const Lesson({
    required this.subject,
    required this.type,
     this.teacher,
    this.room,
     this.building,
    required this.timeStart,
    required this.timeEnd,
    required this.dayOfWeek,
    required this.duration,
    this.subgroup,
    this.stream,
    this.group, 
    this.date,

  });

  String get typeLabel {
    switch (type) {
      case LessonType.lecture:
        return 'Лекция';
      case LessonType.lab:
        return 'Лабораторная';
      case LessonType.practice:
        return 'Практика';
      case LessonType.personal:
        return 'Личное';
      case LessonType.retake:
        return 'Пересдача';
      case LessonType.exam:
        return 'Экзамен';
      case LessonType.examPrep:
        return 'Подготовка к экзамену';
    }
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
  return Lesson(
    subject: json['discipline']?.toString() ?? '',
    type: _lessonTypeFromString(json['kindOfWorkOid']?.toString() ?? ''),
    teacher: json['lecturer_title']?.toString() ?? '',
    room: json['auditorium']?.toString() ?? '',
    building: json['building']?.toString() ?? '',
    timeStart: json['beginLesson']?.toString() ?? '',
    timeEnd: json['endLesson']?.toString() ?? '',
    dayOfWeek: json['dayOfWeek'] is int 
        ? json['dayOfWeek'] as int 
        : int.tryParse(json['dayOfWeek']?.toString() ?? '0') ?? 0,
    date: json['date']?.toString(),
    group: json['group']?.toString(),
    subgroup: json['subGroup']?.toString(),
    stream: json['stream']?.toString(),
    duration: json['lessonNumberStart'] is int 
        ? json['lessonNumberStart'] as int 
        : int.tryParse(json['lessonNumberStart']?.toString() ?? '0') ?? 0

  );
}

  static LessonType _lessonTypeFromString(String s) {
    // return LessonType.values.firstWhere(
    //   (e) => e.name == s,
    //   orElse: () => LessonType.lecture,
    // );

    switch (s) {
      case '1':
        return LessonType.lecture;
      case '2':
        return LessonType.lab;
      case '3':
        return LessonType.practice;
      case '4':
        return LessonType.exam;
      case '5':
        return LessonType.examPrep;
      case '11':
        return LessonType.retake;
      default:
        return LessonType.lecture;
    }
  }

  static LessonStatus _lessonStatusFromString(String s) {
    return LessonStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LessonStatus.active,
    );
  }
}
