import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/news.dart';
import 'schedule_news.dart';

/// Сервис новостей с кешем на диске.
///
/// «Cron» на iOS-клиенте недоступен, поэтому реализуется стратегия
/// «обновление при запуске и возврате в приложение»: лента перепарсивается,
/// если наступил новый календарный день либо с последнего успешного
/// обновления прошло больше [_minRefreshInterval]. В остальных случаях
/// отдаётся кеш — это же обеспечивает работу офлайн.
///
/// Кеш всегда доступен мгновенно через [cachedNews], поэтому экран рисует
/// сохранённую ленту сразу, а сетевой запрос лишь обновляет её потом
/// (stale-while-revalidate) — вместо скелетонов на всё время запроса.
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _fileName = 'news_cache.json';

  /// Минимальный интервал между сетевыми запросами внутри одного дня.
  ///
  /// Нужен, чтобы возврат в приложение каждые несколько минут не приводил
  /// к перепарсингу сайта вуза, но при этом лента обновлялась в течение дня,
  /// а не раз в сутки.
  static const Duration _minRefreshInterval = Duration(hours: 1);

  final NewsRepository _repository = NewsRepositoryImpl();

  List<News>? _memCache;
  DateTime? _fetchedAt;

  /// Идёт ли сейчас сетевой запрос — защита от параллельных обновлений
  /// (экран может дёрнуть обновление и из initState, и из resume).
  Future<NewsLoadResult>? _inFlight;

  /// Время последнего успешного обновления (null — обновлений ещё не было).
  DateTime? get fetchedAt => _fetchedAt;

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Сохранённая лента без обращения к сети. Пустой список — кеша ещё нет.
  Future<List<News>> cachedNews() async {
    await _ensureLoaded();
    return List.unmodifiable(_memCache ?? const <News>[]);
  }

  /// Пора ли идти в сеть.
  bool get _needsRefresh => shouldRefresh(
        fetchedAt: _fetchedAt,
        hasCache: _memCache?.isNotEmpty ?? false,
        now: DateTime.now(),
      );

  /// Чистое правило обновления — вынесено отдельно, чтобы покрывалось тестами.
  ///
  /// Обновляемся, если кеша нет, наступил новый календарный день или с
  /// последнего обновления прошло не меньше [_minRefreshInterval].
  @visibleForTesting
  static bool shouldRefresh({
    required DateTime? fetchedAt,
    required bool hasCache,
    required DateTime now,
  }) {
    if (!hasCache || fetchedAt == null) return true;
    if (!_isSameDay(fetchedAt, now)) return true;
    return now.difference(fetchedAt) >= _minRefreshInterval;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Возвращает новости, при необходимости обновляя их из сети.
  ///
  /// При ошибке сети отдаёт устаревший кеш, если он есть.
  Future<NewsLoadResult> getNews({bool forceRefresh = false}) async {
    await _ensureLoaded();

    if (!forceRefresh && !_needsRefresh) {
      return NewsLoadResult(news: List.unmodifiable(_memCache!));
    }

    // Уже идёт запрос — присоединяемся к нему, а не запускаем второй.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchAndStore();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<NewsLoadResult> _fetchAndStore() async {
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
      _fetchedAt = null;
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
