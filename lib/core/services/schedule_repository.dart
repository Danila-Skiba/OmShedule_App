import 'package:omstu_schedule/data/schedule_data.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';
import '../api/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http ;

class ApiClient implements ScheduleRepository {
  final http.Client client;

  ApiClient({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<ScheduleLoadResult> loadFromApi(
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds}) async{

      try {
        final dateFrom = '${period.startDate.year}-${period.startDate.month.toString().padLeft(2, '0')}-${period.startDate.day.toString().padLeft(2, '0')}';
        final dateTo = '${period.endDate.year}-${period.endDate.month.toString().padLeft(2, '0')}-${period.endDate.day.toString().padLeft(2, '0')}';

        final endpoint = _getEndPoint(groupIds, teacherNames, roomIds);
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
          queryParameters: {
            'date_from': dateFrom,
            'date_to': dateTo,
          }
        );
        final response = await client.get(url, headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        });
        if (response.statusCode != 200) {
          throw Exception('Failed to load schedule (status: ${response.statusCode})');
        }
        final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;

        final lessons = json.map((lesson)=>Lesson.fromJson(lesson)).toList();

        return ScheduleLoadResult(lessons: lessons);
      } catch (e) {
        return ScheduleLoadResult(
          lessons: [],
          error: e.toString());
      }
  }

  String _getEndPoint(String? groupIds, String? teacherNames, String? roomIds) {
    if (groupIds != null) {
      final id = ScheduleData.getgroups[groupIds];
      if (id == null) throw Exception('Unknown group: $groupIds');
      return ApiConfig.scheduleGroup(id.toString());
    }
    if (teacherNames != null) {
      final id = ScheduleData.getpersons[teacherNames];
      if (id == null) throw Exception('Unknown teacher: $teacherNames');
      return ApiConfig.scheduleTeacher(id.toString());
    }
    if (roomIds != null) {
      final id = ScheduleData.getauditorium[roomIds];
      if (id == null) throw Exception('Unknown room: $roomIds');
      return ApiConfig.scheduleAuditorium(id.toString());
    }
    throw Exception('No filter specified');
  }
}

class ScheduleLoadResult {
  final List<Lesson> lessons;
  final String? error;

  const ScheduleLoadResult({required this.lessons, this.error});

  bool get hasError => error != null;
}

abstract class ScheduleRepository {
  Future<ScheduleLoadResult> loadFromApi(
    WeekPeriod period, {
    String? groupIds,
    String? teacherNames,
    String? roomIds,
  });
}
