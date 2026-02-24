
class ScheduleData {
 static const  Map<String, String> groups = {
    'МО-231': '484',
    'ФИТ-231': '687',
  };

  List<String> get groupsList => groups.keys.toList();

  static const Map<String, String> teachers = {
    'Гуненков М.Ю': '1003026',
    'Шарун И.В': '782898',
  };

  List<String> get teachersList => teachers.keys.toList();

  static const Map<String, String> rooms = {
    'Г-331': '38',
    '8-222': '165',
  };

  List<String> get roomsList => rooms.keys.toList();
}