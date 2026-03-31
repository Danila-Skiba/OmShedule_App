



import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'shedule_data.dart';

class ScheduleDataApi {
  final baseUrl = 'http://localhost:8000/api';
  final http.Client client = http.Client();

  Future<Map <String, String>> getInfo(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load schedule');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
  
    final Map<String, String> info = {  
      for (var part in json)
        part['name'].toString(): part['id'].toString(),
    };

    return info;
  }
}






class ScheduleData {
  //  static  Map<String, String> groups = {};
  //  static  Map<String, String> persons = {};
  //  static  Map<String, String> auditorium = {};

  static Map<String, String> get getgroups { 
    return groupsData;
  }

  static Map<String, String> get getpersons {
    return personsData;

  }

  static Map<String, String> get getauditorium {
    return rooms;
  }

  
  // static Future update_groups() async {
  //   groups = await ScheduleDataApi().getInfo('groups');
  // }

  // static Future update_persons() async {
  //   persons = await ScheduleDataApi().getInfo('persons');
  // }

  // static Future update_auditorium() async {
  //   auditorium = await ScheduleDataApi().getInfo('auditories');
  // }
}