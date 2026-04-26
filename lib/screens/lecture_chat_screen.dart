import 'package:flutter/material.dart';
import '../models/lecture_session.dart';
import '../widgets/app_dialog.dart';

/// Экран чата с ботом для записи конспекта.
/// Загрузка фото + сообщение, кнопка «Готово» сверху.
class LectureChatScreen extends StatefulWidget {
  final LectureSession session;

  const LectureChatScreen({super.key, required this.session});

  @override
  State<LectureChatScreen> createState() => _LectureChatScreenState();
}

class _LectureChatScreenState extends State<LectureChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<LectureChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Приветственное сообщение бота
    _messages.add(LectureChatMessage(
      id: 'welcome',
      text:
          'Привет! Я помогу записать конспект по предмету «${widget.session.subject}».\n\nОтправляйте фото доски или слайдов, и я добавлю их в конспект. Можете приложить текстовый комментарий к каждому фото.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? imagePath}) {
    final text = _textController.text.trim();
    if (text.isEmpty && imagePath == null) return;

    setState(() {
      _messages.add(LectureChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.isNotEmpty ? text : null,
        imagePath: imagePath,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    // Имитация ответа бота
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(LectureChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          text: imagePath != null
              ? 'Фото добавлено в конспект. Всего фото: ${_messages.where((m) => m.isUser && m.imagePath != null).length}.'
              : 'Заметка сохранена.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _pickPhoto() {
    // TODO: реальный image_picker
    // Для демонстрации отправляем «фото-заглушку»
    _sendMessage(imagePath: 'demo_photo');
  }

  void _finishSession() {
    AppDialog.show(
      context: context,
      icon: Icons.check_circle_outline_rounded,
      title: 'Завершить сессию?',
      message:
          'Конспект по «${widget.session.subject}» будет сохранён. Вы сможете скомпилировать его позже.',
      confirmText: 'Готово',
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.subject,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.session.topic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
        actions: [
          // Кнопка «Готово»
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _finishSession,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    'Готово',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Список сообщений ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Индикатор «бот печатает»
                  return _TypingIndicator();
                }
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChatBubble(message: msg),
                );
              },
            ),
          ),

          // ── Панель ввода ──
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withOpacity(0.5),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                // Кнопка прикрепить фото
                Material(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 22,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Поле ввода
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Комментарий к фото...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: onSurface.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Кнопка отправить
                Material(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _sendMessage(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.send_rounded,
                        size: 22,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Пузырь сообщения
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final LectureChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? primary
        : (isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF0F2F5));

    final textColor = isUser
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Превью фото (заглушка)
              if (message.imagePath != null) ...[
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withOpacity(0.15)
                        : primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 36,
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Фото лекции',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.text != null) const SizedBox(height: 8),
              ],
              // Текст
              if (message.text != null)
                Text(
                  message.text!,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              // Время
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Индикатор «бот печатает»
// ═══════════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF0F2F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 600 + i * 200),
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.25 * value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
