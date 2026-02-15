/// Модель задачи (из mockData.ts)
class Task {
  final String id;
  final String title;
  final String deadline;
  final bool completed;

  const Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.completed,
  });

  Task copyWith({
    String? id,
    String? title,
    String? deadline,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      completed: completed ?? this.completed,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      deadline: json['deadline'] as String,
      completed: json['completed'] as bool,
    );
  }
}
