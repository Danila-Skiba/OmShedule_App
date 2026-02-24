import 'package:omstu_schedule/data/schedule_data.dart';
import '../../data/schedule_mock_data.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';
import 'dart:convert';
import 'package:http/http.dart' as http ;

class ApiClient implements ScheduleRepository {
  final String? baseUrl;
  final http.Client client;

  ApiClient({
    this.baseUrl = 'https://rasp.omgtu.ru/api/schedule',
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  Future<ScheduleLoadResult> loadFromApi(
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames, 
    String? roomIds}) async{

      try {
        
        final url = Uri.parse('$baseUrl/${_getEndPoint(groupIds, teacherNames, roomIds)}').replace(
          queryParameters: {
            'start': period.startDate.toIso8601String().replaceAll('-', '.'),
            'finish': period.endDate.toIso8601String().replaceAll('-', '.'),
          }
        );
        final response = await client.get(url, headers: {'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',});
        if (response.statusCode != 200) {
          throw Exception('Failed to load schedule');
        }
        final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
        print(json);
        final lessons = json.map((lesson)=>Lesson.fromJson(lesson)).toList();
        print(lessons);
        return ScheduleLoadResult(lessons: lessons);
      } catch (e) {
        return ScheduleLoadResult(
          lessons: [],
          error: e.toString());
      }
    
    
  }

  String _getEndPoint(String? groupIds, String? teacherNames,  String? roomIds) {
    if (groupIds != null) return 'group/${ScheduleData.groups[groupIds]}';
    if (teacherNames != null) return 'person/${ScheduleData.teachers[teacherNames]}';
    if (roomIds != null) return 'auditorium/${ScheduleData.rooms[roomIds]}';
    return '';
  }
}
class ScheduleLoadResult {
  final List<Lesson> lessons; //cписок занятий, которые получаем из API
  final String? error; // ошибка

  const ScheduleLoadResult({required this.lessons, this.error});

  bool get hasError => error != null; /// есть ли ошибка 
}

abstract class ScheduleRepository {
  Future<ScheduleLoadResult> loadFromApi(
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  });
}