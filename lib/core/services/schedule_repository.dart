import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:omstu_schedule/data/schedule_data.dart';
import '../../models/lesson.dart';
import '../../models/week_period.dart';

/// Клиент расписания — тянет данные напрямую из открытого API ОмГТУ.
///
/// Базовый адрес: https://rasp.omgtu.ru/api/schedule
/// Эндпоинты: group/{id}, person/{id}, auditorium/{id}
/// Параметры периода: start / finish в формате YYYY.MM.DD
class ApiClient implements ScheduleRepository {
  final String baseUrl;
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
    String? roomIds,
  }) async {
    try {
      final endpoint = _getEndPoint(groupIds, teacherNames, roomIds);
      final url = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters: {
          'start': _formatDate(period.startDate),
          'finish': _formatDate(period.endDate),
          'lng': '1',
        },
      );

      final response = await client.get(url, headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to load schedule (status: ${response.statusCode})');
      }

      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
      final lessons = json
          .map((lesson) => Lesson.fromJson(lesson as Map<String, dynamic>))
          .toList();

      return ScheduleLoadResult(lessons: lessons);
    } catch (e) {
      return ScheduleLoadResult(lessons: [], error: e.toString());
    }
  }

  /// Дата в формате API вуза: YYYY.MM.DD
  static String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}.$m.$d';
  }

  /// Строит эндпоинт по выбранному фильтру, подставляя id из справочников.
  String _getEndPoint(String? groupIds, String? teacherNames, String? roomIds) {
    if (groupIds != null) {
      final id = ScheduleData.getgroups[groupIds];
      if (id == null) throw Exception('Unknown group: $groupIds');
      return 'group/$id';
    }
    if (teacherNames != null) {
      final id = ScheduleData.getpersons[teacherNames];
      if (id == null) throw Exception('Unknown teacher: $teacherNames');
      return 'person/$id';
    }
    if (roomIds != null) {
      final id = ScheduleData.getauditorium[roomIds];
      if (id == null) throw Exception('Unknown room: $roomIds');
      return 'auditorium/$id';
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
