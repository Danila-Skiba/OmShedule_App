import 'dart:convert';
import 'package:http/http.dart' as http ;
import 'package:omstu_schedule/models/news.dart';

const _host = '172.20.10.8'; //localhost
// const _host = 'localhost';

abstract class NewsRepository {
  Future<NewsLoadResult> getNews();
}

class NewsRepositoryImpl extends NewsRepository {

  final String baseUrl = 'http://$_host:8000/api/news/';
  final http.Client client; 

  NewsRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override

  Future<NewsLoadResult> getNews() async {
    try {

      final url = Uri.parse(baseUrl);

      final response = await client.get(url, headers: {'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',});
      if (response.statusCode != 200){
        throw Exception('Failed to load news');
      }
      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;

      final news = json.map((n)=>News.fromJson(n)).toList();

      return NewsLoadResult(news:   news);

    } catch (e) {
      return NewsLoadResult(
        news: [],
        error: e.toString(),
      );
    }
  }
}

class NewsLoadResult {
  final List<News> news;
  final String? error;
  NewsLoadResult({required this.news, this.error});
}