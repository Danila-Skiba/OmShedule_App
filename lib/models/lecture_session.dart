/// Модель сессии конспекта лекции.
class LectureSession {
  final String id;
  final String subject;
  final String topic;
  final DateTime dateTime;
  final bool isActive;
  final int photoCount;
  final String? filePath; // путь к скомпилированному PDF (для недавних)
  final String? mdContent; // содержимое конспекта в формате Markdown

  const LectureSession({
    required this.id,
    required this.subject,
    required this.topic,
    required this.dateTime,
    this.isActive = true,
    this.photoCount = 0,
    this.filePath,
    this.mdContent,
  });

  LectureSession copyWith({
    String? id,
    String? subject,
    String? topic,
    DateTime? dateTime,
    bool? isActive,
    int? photoCount,
    String? filePath,
    String? mdContent,
  }) {
    return LectureSession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      dateTime: dateTime ?? this.dateTime,
      isActive: isActive ?? this.isActive,
      photoCount: photoCount ?? this.photoCount,
      filePath: filePath ?? this.filePath,
      mdContent: mdContent ?? this.mdContent,
    );
  }
}

/// Сообщение в чате конспекта.
class LectureChatMessage {
  final String id;
  final String? text;
  final String? imagePath;
  final bool isUser;
  final DateTime timestamp;

  const LectureChatMessage({
    required this.id,
    this.text,
    this.imagePath,
    required this.isUser,
    required this.timestamp,
  });
}
