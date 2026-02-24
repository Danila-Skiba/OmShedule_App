/// Личная задача пользователя.
/// Привязана к конкретной дате и времени.
class PersonalTask {
  final String id;
  final String title;
  /// Время в формате HH:mm 
  final String time;
  /// Аудитория/место 
  final String? audience;
  /// Дата в формате yyyy-MM-dd.
  final String date;
  /// Временная метка создания (ISO 8601).
  final String createdAt;
  /// Отмечена ли задача как выполненная.
  final bool completed;

  const PersonalTask({
    required this.id,
    required this.title,
    required this.time,
    this.audience,
    required this.date,
    required this.createdAt,
    this.completed = false,
  });

  PersonalTask copyWith({
    String? id,
    String? title,
    String? time,
    String? audience,
    String? date,
    String? createdAt,
    bool? completed,
  }) {
    return PersonalTask(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      audience: audience ?? this.audience,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'audience': audience,
      'date': date,
      'createdAt': createdAt,
      'completed': completed,
    };
  }

  factory PersonalTask.fromJson(Map<String, dynamic> json) {
    return PersonalTask(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      audience: json['audience'] as String?,
      date: json['date'] as String,
      createdAt: json['createdAt'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
