import 'package:enough_convert/enough_convert.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'package:omstu_schedule/models/news.dart';

/// Репозиторий новостей — парсит ленту прямо с сайта ОмГТУ.
///
/// Раньше парсинг выполнял python-скрипт на бэкенде; теперь логика
/// перенесена в клиент. Страница отдаётся в кодировке windows-1251.
abstract class NewsRepository {
  Future<NewsLoadResult> getNews();
}

class NewsRepositoryImpl extends NewsRepository {
  final http.Client client;

  /// Адрес ленты новостей вуза.
  static const String newsUrl = 'https://www.omgtu.ru/news/';

  static final Uri _base = Uri.parse(newsUrl);
  static const Windows1251Codec _cp1251 = Windows1251Codec(allowInvalid: true);

  NewsRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<NewsLoadResult> getNews() async {
    try {
      final response = await client.get(
        _base,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept': 'text/html',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load news (status: ${response.statusCode})');
      }

      // Сайт вуза в windows-1251 — декодируем байты вручную.
      final body = _cp1251.decode(response.bodyBytes);
      final document = html_parser.parse(body);

      final news = document
          .querySelectorAll('div.news-card')
          .map(_parseCard)
          .whereType<News>()
          .toList();

      // Сортируем по дате (убывание — новые сверху). При отсутствии даты
      // сохраняем исходный порядок страницы (она и так новые сверху).
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
      return NewsLoadResult(news: [], error: e.toString());
    }
  }

  /// Разбирает одну карточку `div.news-card`.
  News? _parseCard(dom.Element card) {
    final link = card.querySelector('a.news-card__image') ??
        card.querySelector('a[href]');
    final href = link?.attributes['href'];
    if (href == null || href.isEmpty) return null;

    final newsUrl = _base.resolve(href).toString();
    final id = _newsId(newsUrl);

    final img = card.querySelector('img');
    final imgSrc = img?.attributes['src'];
    final imageUrl =
        (imgSrc != null && imgSrc.isNotEmpty) ? _base.resolve(imgSrc).toString() : null;

    final title = (card.querySelector('.news-card__title')?.text ??
            img?.attributes['alt'] ??
            img?.attributes['title'] ??
            '')
        .trim();

    final date = card.querySelector('.news-card__date')?.text.trim() ?? '';

    return News(
      id: id,
      title: title,
      date: date,
      url: newsUrl,
      image: imageUrl,
    );
  }

  /// Извлекает идентификатор новости из ссылки (`?eid=111012`).
  static String _newsId(String url) {
    final idx = url.indexOf('eid=');
    if (idx < 0) return url;
    final rest = url.substring(idx + 4);
    final amp = rest.indexOf('&');
    return amp < 0 ? rest : rest.substring(0, amp);
  }
}

class NewsLoadResult {
  final List<News> news;
  final String? error;
  NewsLoadResult({required this.news, this.error});
}
