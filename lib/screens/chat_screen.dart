import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';

/// Чат-помощник (эквивалент Chat.tsx)
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'Привет! Я помощник ОмГТУ на базе Gigachat. Чем могу помочь?',
      sender: MessageSender.bot,
      timestamp: DateFormat.Hm().format(DateTime.now()),
    ),
  ];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
  }

  static const _quickPrompts = [
    'Составь план на неделю',
    'Что задали по матану?',
    'Расскажи про Петрова',
    'Где ближайшее кафе?',
  ];

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateFormat.Hm().format(DateTime.now()),
    );
    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
    });

    // Симуляция ответа бота
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final botText = _getBotResponse(text);
      setState(() {
        _messages.add(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          text: botText,
          sender: MessageSender.bot,
          timestamp: DateFormat.Hm().format(DateTime.now()),
        ));
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getBotResponse(String userInput) {
    final lower = userInput.toLowerCase();
    if (lower.contains('план') || lower.contains('неделю')) {
      return '📅 Вот твой план на неделю:\n\n• ПН: Математический анализ (08:30), Физика (11:00)\n• ВТ: Английский язык (08:30), Базы данных (11:00)\n• СР: Дискретная математика (08:30)\n\nНе забудь сдать лабу по матану до завтра!';
    }
    if (lower.contains('матан') || lower.contains('математик')) {
      return '📚 По математическому анализу:\n• Лабораторная работа №3 - сдать завтра\n• Подготовиться к семинару по теме "Интегралы"\n• Решить задачи №12-18 из учебника';
    }
    if (lower.contains('петров')) {
      return '👨‍🏫 Петров Владимир Владимирович:\n• Рейтинг: 4.2/5.0 (127 отзывов)\n• Предмет: Математический анализ\n• Кабинет: 312, Корпус 3\n• Студенты отмечают: строгий, но справедливый преподаватель';
    }
    if (lower.contains('кафе') || lower.contains('столовая')) {
      return '☕ Ближайшие места:\n\n1. Столовая ОмГТУ - 50м, 1 мин\n   ⭐ 4.5 (234 отзыва)\n\n2. Кофейня "Энергия" - 120м, 2 мин\n   ⭐ 4.8 (89 отзывов)\n\nОбе работают с 08:00 до 18:00';
    }
    return 'Понял твой запрос! Я помогу с расписанием, задачами, информацией о преподавателях и навигацией по университету. Задай более конкретный вопрос 😊';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length <= 1) _buildQuickPrompts(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Помощник Gigachat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Онлайн',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Быстрые команды:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) => ActionChip(
              label: Text(prompt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.border),
              onPressed: () {
                _inputController.text = prompt;
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: 'Напиши сообщение...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () {},
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _inputController,
              builder: (_, value, __) {
                final hasText = value.text.trim().isNotEmpty;
                return Material(
                  color: hasText ? AppColors.primaryLight : AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: hasText ? _sendMessage : null,
                borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    
                    color: isUser ? AppColors.primaryLight : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(color: Color.fromARGB(255, 220, 220, 220), blurRadius: 2, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    message.timestamp,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.success, Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
