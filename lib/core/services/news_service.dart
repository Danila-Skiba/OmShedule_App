import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/news.dart';
import 'schedule_news.dart';

/// Сервис новостей с суточным кешем.
///
/// «Cron» на iOS-клиенте недоступен, поэтому реализуется стратегия
/// «обновление при запуске»: новости перепарсиваются, если с последнего
/// успешного обновления прошло больше [_ttl]; иначе отдаётся кеш
/// (это же обеспечивает работу офлайн).
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _fileName = 'news_cache.json';
  static const Duration _ttl = Duration(hours: 24);

  final NewsRepository _repository = NewsRepositoryImpl();

  List<News>? _memCache;
  DateTime? _fetchedAt;

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Возвращает новости. Если кеш свежий (моложе суток) и не запрошено
  /// принудительное обновление — берёт из кеша, иначе перепарсивает ленту.
  /// При ошибке сети отдаёт устаревший кеш, если он есть.
  Future<NewsLoadResult> getNews({bool forceRefresh = false}) async {
    await _ensureLoaded();

    final fresh = _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _ttl &&
        (_memCache?.isNotEmpty ?? false);

    if (fresh && !forceRefresh) {
      return NewsLoadResult(news: List.unmodifiable(_memCache!));
    }

    final result = await _repository.getNews();

    if (result.error == null && result.news.isNotEmpty) {
      _memCache = result.news;
      _fetchedAt = DateTime.now();
      await _persist();
      return result;
    }

    // Сеть недоступна/ошибка — отдаём устаревший кеш, если он есть.
    if (_memCache?.isNotEmpty ?? false) {
      return NewsLoadResult(news: List.unmodifiable(_memCache!));
    }
    return result;
  }

  /// Загружает кеш из памяти или с диска (однократно).
  Future<void> _ensureLoaded() async {
    if (_memCache != null) return;
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        _memCache = [];
        return;
      }
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final fetchedAt = map['fetchedAt'] as String?;
      _fetchedAt = fetchedAt != null ? DateTime.tryParse(fetchedAt) : null;
      final list = (map['news'] as List<dynamic>? ?? [])
          .map((e) => News.fromJson(e as Map<String, dynamic>))
          .toList();
      _memCache = list;
    } catch (e) {
      debugPrint('NewsService: ошибка чтения кеша: $e');
      _memCache = [];
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _cacheFile();
      final data = {
        'fetchedAt': _fetchedAt?.toIso8601String(),
        'news': _memCache?.map((n) => n.toJson()).toList() ?? [],
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('NewsService: ошибка записи кеша: $e');
    }
  }
}
