import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_config.dart';

/// Модель пользователя.
class UserProfile {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Сервис авторизации — хранит JWT, проверяет валидность, даёт методы login/register/logout.
class AuthService extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';
  static const _loginTimeKey = 'jwt_login_time';
  static const _tokenLifetimeMinutes = 10080; // 7 дней

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final http.Client _client = http.Client();
  String? _token;
  UserProfile? _user;
  bool _initialized = false;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  UserProfile? get user => _user;
  bool get initialized => _initialized;

  /// Инициализация: загрузить токен из SharedPreferences и провалидировать.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final loginTime = prefs.getInt(_loginTimeKey);

    if (storedToken != null && loginTime != null) {
      // Проверяем не истёк ли локально
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTime);
      final diff = DateTime.now().difference(loginDate).inMinutes;
      if (diff >= _tokenLifetimeMinutes) {
        await _clearToken();
      } else {
        _token = storedToken;
        // Валидируем на сервере
        final valid = await _validateRemote();
        if (!valid) {
          await _clearToken();
        } else {
          // Загружаем профиль
          await _loadProfile();
        }
      }
    }
    _initialized = true;
    notifyListeners();
  }

  /// Авторизация.
  Future<String?> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authLogin}');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _token = json['access_token'] as String;
        await _saveToken();
        await _loadProfile();
        notifyListeners();
        return null; // успех
      } else {
        final body = jsonDecode(response.body);
        return body['detail']?.toString() ?? 'Ошибка авторизации';
      }
    } catch (e) {
      return 'Ошибка сети: $e';
    }
  }

  /// Регистрация.
  Future<String?> register(String name, String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authRegister}');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // После регистрации — сразу логинимся
        return await login(email, password);
      } else {
        final body = jsonDecode(response.body);
        return body['detail']?.toString() ?? 'Ошибка регистрации';
      }
    } catch (e) {
      return 'Ошибка сети: $e';
    }
  }

  /// Выход.
  Future<void> logout() async {
    await _clearToken();
    _user = null;
    notifyListeners();
  }

  /// Получить заголовок авторизации.
  Map<String, String> get authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> _validateRemote() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authValidate}');
      final response = await _client.get(url, headers: {
        'Authorization': 'Bearer $_token',
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['valid'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authMe}');
      final response = await _client.get(url, headers: {
        'Authorization': 'Bearer $_token',
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _user = UserProfile.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_loginTimeKey);
  }
}
