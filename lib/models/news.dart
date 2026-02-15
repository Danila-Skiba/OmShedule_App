/// Модель новости (из mockData.ts)
class News {
  final String id;
  final String title;
  final String date;
  final String preview;

  const News({
    required this.id,
    required this.title,
    required this.date,
    required this.preview,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      preview: json['preview'] as String,
    );
  }
}
