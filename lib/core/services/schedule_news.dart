import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:omstu_schedule/models/news.dart';
import '../api/api_config.dart';

abstract class NewsRepository {
  Future<NewsLoadResult> getNews();
}

class NewsRepositoryImpl extends NewsRepository {
  final http.Client client;

  NewsRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<NewsLoadResult> getNews() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.news}');

      final response = await client.get(url, headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to load news');
      }
      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;

      final news = json.map((n) => News.fromJson(n)).toList();

      // Сортируем по дате (убывание — новые сверху)
      news.sort((a, b) {
        final da = a.parsedDate;
        final db = b.parsedDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      return NewsLoadResult(news: news);
    } catch (e) {
      return NewsLoadResult(
        news: [],
        error: e.toString(),
      );
    }
  }

  /// URL изображения новости.
  static String imageUrl(String newsId) =>
      '${ApiConfig.baseUrl}${ApiConfig.newsImage(newsId)}';
}

class NewsLoadResult {
  final List<News> news;
  final String? error;
  NewsLoadResult({required this.news, this.error});
}
