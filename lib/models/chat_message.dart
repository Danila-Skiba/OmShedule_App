/// Отправитель сообщения в чате (соответствует "user" | "bot")
enum MessageSender {
  user,
  bot,
}

/// Модель сообщения чата (из Chat.tsx interface Message)
class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final String timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
