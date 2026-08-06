/// Модель новости ОмГТУ (парсится с сайта вуза).
class News {
  final String id;
  final String title;

  /// Дата в формате dd.MM.yyyy (как на сайте вуза).
  final String date;

  /// Ссылка на страницу новости.
  final String url;

  /// Полный URL изображения новости (или null).
  final String? image;

  const News({
    required this.id,
    required this.title,
    required this.date,
    required this.url,
    this.image,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'].toString(),
      title: json['title'] as String,
      date: json['date'] as String,
      url: json['url'] as String,
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'url': url,
        'image': image,
      };

  /// Парсинг даты для сортировки.
  DateTime? get parsedDate {
    try {
      // Формат может быть "dd.MM.yyyy" или "yyyy-MM-dd"
      if (date.contains('-')) return DateTime.parse(date);
      final parts = date.split('.');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
