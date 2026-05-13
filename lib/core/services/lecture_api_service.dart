import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import 'auth_service.dart';

/// Модель сессии лекции из API.
class ApiLectureSession {
  final String sessionId;
  final String subject;
  final DateTime createdAt;
  final DateTime? compiledAt;
  final bool isCompiled;
  final String? mdContent;

  const ApiLectureSession({
    required this.sessionId,
    required this.subject,
    required this.createdAt,
    this.compiledAt,
    this.isCompiled = false,
    this.mdContent,
  });

  /// Смещение для Омского времени (UTC+6).
  static const _omskOffset = Duration(hours: 6);

  static DateTime _toOmsk(String dateStr) {
    final utc = DateTime.parse(dateStr);
    return utc.add(_omskOffset);
  }

  factory ApiLectureSession.fromJson(Map<String, dynamic> json) {
    return ApiLectureSession(
      sessionId: json['session_id'] as String,
      subject: json['subject'] as String,
      createdAt: _toOmsk(json['created_at'] as String),
      compiledAt: json['compiled_at'] != null
          ? _toOmsk(json['compiled_at'] as String)
          : null,
      isCompiled: json['is_compiled'] as bool? ?? false,
      mdContent: json['md_content'] as String?,
    );
  }
}

/// Результат загрузки фрагмента.
class FragmentResult {
  final int fragmentIndex;
  final String mdText;

  const FragmentResult({required this.fragmentIndex, required this.mdText});

  factory FragmentResult.fromJson(Map<String, dynamic> json) {
    return FragmentResult(
      fragmentIndex: json['fragment_index'] as int,
      mdText: json['md_text'] as String,
    );
  }
}

/// Результат компиляции.
class CompileResult {
  final String sessionId;
  final String mdContent;

  const CompileResult({required this.sessionId, required this.mdContent});

  factory CompileResult.fromJson(Map<String, dynamic> json) {
    return CompileResult(
      sessionId: json['session_id'] as String,
      mdContent: json['md_content'] as String,
    );
  }
}

/// Сервис для работы с API конспектов.
class LectureApiService {
  static LectureApiService? _instance;
  static LectureApiService get instance => _instance ??= LectureApiService._();

  LectureApiService._();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => AuthService.instance.authHeaders;

  /// Создать новую сессию.
  Future<ApiLectureSession> createSession(String subject) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.lectureSessionCreate}')
        .replace(queryParameters: {'subject': subject});
    final response = await _client.post(url, headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiLectureSession.fromJson(json);
    }
    throw Exception('Не удалось создать сессию: ${response.statusCode} ${response.body}');
  }

  /// Загрузить фото в сессию.
  Future<FragmentResult> uploadPhoto(
    String sessionId,
    File imageFile, {
    String comment = '',
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.lectureSessionData(sessionId)}',
    ).replace(queryParameters: {'comment': comment});

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer ${AuthService.instance.token}';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FragmentResult.fromJson(json);
    }
    throw Exception('Ошибка загрузки фото: ${response.statusCode} ${response.body}');
  }

  /// Скомпилировать сессию.
  Future<CompileResult> compileSession(String sessionId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.lectureSessionCompile(sessionId)}',
    );
    final response = await _client.post(url, headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CompileResult.fromJson(json);
    }
    throw Exception('Ошибка компиляции: ${response.statusCode} ${response.body}');
  }

  /// Получить все сессии пользователя.
  Future<List<ApiLectureSession>> getAllSessions() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.lectures}');
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
      return json.map((e) => ApiLectureSession.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Ошибка загрузки сессий: ${response.statusCode}');
  }

  /// Получить сессию по ID.
  Future<ApiLectureSession> getSession(String sessionId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.lectureSession(sessionId)}',
    );
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiLectureSession.fromJson(json);
    }
    throw Exception('Сессия не найдена: ${response.statusCode}');
  }

  /// Удалить сессию.
  Future<void> deleteSession(String sessionId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.lectureSession(sessionId)}',
    );
    final response = await _client.delete(url, headers: _headers);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления: ${response.statusCode}');
    }
  }
}
