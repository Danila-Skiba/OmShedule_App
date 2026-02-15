/// Модель преподавателя (из mockData.ts)
class Teacher {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;

  const Teacher({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
    );
  }
}
