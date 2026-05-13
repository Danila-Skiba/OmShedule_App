/// Конфигурация API.
class ApiConfig {
  ApiConfig._();


  static const String host = 'localhost'
;
  static const int port = 8000;
  static const String baseUrl = 'http://$host:$port';

  // Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authMe = '/api/auth/me';
  static const String authValidate = '/api/auth/validate';

  static const String news = '/api/news';
  static String newsImage(String id) => '/api/news/images/$id';

  static String scheduleGroup(String id) => '/api/schedule/group/$id';
  static String scheduleTeacher(String id) => '/api/schedule/teacher/$id';
  static String scheduleAuditorium(String id) => '/api/schedule/auditorium/$id';

  static const String lectures = '/api/lectures/lectures';
  static String lectureSession(String id) => '/api/lectures/session/$id';
  static String lectureSessionData(String id) => '/api/lectures/session/$id/data';
  static String lectureSessionCompile(String id) => '/api/lectures/session/$id/compile';
  static const String lectureSessionCreate = '/api/lectures/session';
}
