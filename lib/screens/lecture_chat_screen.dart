import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import '../core/services/lecture_api_service.dart';
import '../core/utils/platform_utils.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import 'markdown_viewer_screen.dart';

/// Экран чата с ботом для записи конспекта.
/// Загрузка фото + комментарий → получение md фрагмента от API.
class LectureChatScreen extends StatefulWidget {
  final String sessionId;
  final String subject;

  const LectureChatScreen({
    super.key,
    required this.sessionId,
    required this.subject,
  });

  @override
  State<LectureChatScreen> createState() => _LectureChatScreenState();
}

class _LectureChatScreenState extends State<LectureChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;
  bool _isCompiling = false;
  File? _pendingPhoto;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text:
          'Привет! Я помогу записать конспект по предмету «${widget.subject}».\n\n'
          'Отправляйте фото доски или слайдов, и я распознаю и добавлю их в конспект. '
          'Можете приложить текстовый комментарий к каждому фото.\n\n'
          'Когда закончите — нажмите «Скомпилировать».',
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

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;
    setState(() => _pendingPhoto = File(picked.path));
  }

  void _clearPendingPhoto() {
    setState(() => _pendingPhoto = null);
  }

  Future<void> _sendPending() async {
    final photo = _pendingPhoto;
    if (photo == null) return;

    final comment = _textController.text.trim();
    _textController.clear();

    setState(() {
      _pendingPhoto = null;
      _messages.add(_ChatMessage(
        text: comment.isNotEmpty ? comment : null,
        imagePath: photo.path,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await LectureApiService.instance.uploadPhoto(
        widget.sessionId,
        photo,
        comment: comment,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(_ChatMessage(
          text: result.mdText,
          isUser: false,
          timestamp: DateTime.now(),
          isMarkdown: true,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().toLowerCase();
      final isReadError = errorText.contains('чтен') || errorText.contains('read') || errorText.contains('decode') || errorText.contains('parse');
      setState(() {
        _isSending = false;
        _messages.add(_ChatMessage(
          text: isReadError ? 'Ошибка чтения фото' : 'Ошибка загрузки: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
      _scrollToBottom();
    }
  }

  void _showPickerOptions() {
    if (isIOS) { // iOS
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
              child: const Text('Камера'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
              child: const Text('Галерея'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera_rounded, color: theme.colorScheme.primary),
                  title: const Text('Камера'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
                  title: const Text('Галерея'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _compileSession() async {
    AppDialog.show(
      context: context,
      icon: Icons.auto_awesome_rounded,
      title: 'Скомпилировать конспект?',
      message:
          'Все загруженные фрагменты будут объединены в один Markdown-конспект. '
          'После компиляции сессия станет завершённой.',
      confirmText: 'Скомпилировать',
      onConfirm: () async {
        setState(() => _isCompiling = true);
        try {
          final result = await LectureApiService.instance.compileSession(widget.sessionId);
          if (!mounted) return;
          setState(() => _isCompiling = false);
          AppSnackBar.success(context, 'Конспект скомпилирован!');
          // Открываем просмотр
          Navigator.of(context).pushReplacement( // iOS
            buildRoute(MarkdownViewerScreen(
              title: widget.subject,
              subtitle: 'Скомпилировано сейчас',
              markdownContent: result.mdContent,
            )),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isCompiling = false);
          AppSnackBar.error(context, 'Ошибка компиляции: $e');
        }
      },
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
              widget.subject,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Сессия конспекта',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        actions: [
          // Кнопка «Скомпилировать»
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: _isCompiling ? primary.withValues(alpha: 0.5) : primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _isCompiling ? null : _compileSession,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _isCompiling
                      ? buildSmallLoader(color: theme.colorScheme.onPrimary) // iOS
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 15, color: theme.colorScheme.onPrimary),
                            const SizedBox(width: 5),
                            Text(
                              'Скомпилировать',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
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
                  return const _TypingIndicator();
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
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Превью выбранного фото
                if (_pendingPhoto != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _pendingPhoto!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: _clearPendingPhoto,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    // Кнопка прикрепить фото
                    Material(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _isSending ? null : _showPickerOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 22,
                            color: _isSending ? primary.withValues(alpha: 0.4) : primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Поле ввода комментария
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
                            hintText: _pendingPhoto != null
                                ? 'Комментарий к фото...'
                                : 'Сначала прикрепите фото',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: onSurface.withValues(alpha: 0.35),
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
                    // Кнопка отправить (активна только с фото)
                    Material(
                      color: (_pendingPhoto != null && !_isSending)
                          ? primary
                          : primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: (_pendingPhoto != null && !_isSending) ? _sendPending : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.send_rounded,
                            size: 22,
                            color: (_pendingPhoto != null && !_isSending)
                                ? theme.colorScheme.onPrimary
                                : primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// Модель сообщения чата
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  final String? text;
  final String? imagePath;
  final bool isUser;
  final DateTime timestamp;
  final bool isMarkdown;
  final bool isError;

  const _ChatMessage({
    this.text,
    this.imagePath,
    required this.isUser,
    required this.timestamp,
    this.isMarkdown = false,
    this.isError = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Пузырь сообщения
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final isUser = message.isUser;

    final bubbleColor = message.isError
        ? (isDark ? const Color(0xFF3D2020) : const Color(0xFFFDE8E8))
        : isUser
            ? primary
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F2F5));

    final textColor = message.isError
        ? (isDark ? const Color(0xFFFF8A8A) : const Color(0xFFB91C1C))
        : isUser
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Превью фото
              if (message.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(message.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.15)
                            : primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 36,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.7)
                            : primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                if (message.text != null) const SizedBox(height: 8),
              ],
              // Текст (с Markdown для ответов бота)
              if (message.text != null)
                message.isMarkdown && !isUser
                    ? _buildBotMessageWithMath(message.text!, textColor, isDark)
                    : Text(
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
                        ? Colors.white.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });
    // Stagger start with delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F2F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'Обработка фото',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controllers[i],
                builder: (_, __) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.2 + 0.5 * _controllers[i].value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Конвертация инлайн-формул и Math builder для чата
// ═══════════════════════════════════════════════════════════════════════════════

/// Строит виджет сообщения бота с поддержкой блочных $$...$$ и инлайн $...$ формул.
Widget _buildBotMessageWithMath(String text, Color textColor, bool isDark) {
  // Разбиваем текст на блоки: обычный текст и блочные формулы $$...$$
  final blocks = _parseChatBlocks(text);

  if (blocks.length == 1 && !blocks.first.isMath) {
    // Нет блочных формул — только инлайн
    return MarkdownBody(
      data: _convertInlineMathToCode(text),
      selectable: true,
      fitContent: true,
      builders: {
        'code': _ChatMathBuilder(textColor: textColor, isDark: isDark),
      },
      styleSheet: _chatMarkdownStyle(textColor, isDark),
    );
  }

  // Есть блочные формулы — строим список виджетов
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: blocks.map((block) {
      if (block.isMath) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                block.content.trim(),
                textStyle: TextStyle(fontSize: 16, color: textColor),
                mathStyle: MathStyle.display,
              ),
            ),
          ),
        );
      } else {
        final trimmed = block.content.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();
        return MarkdownBody(
          data: _convertInlineMathToCode(trimmed),
          selectable: true,
          fitContent: true,
          builders: {
            'code': _ChatMathBuilder(textColor: textColor, isDark: isDark),
          },
          styleSheet: _chatMarkdownStyle(textColor, isDark),
        );
      }
    }).toList(),
  );
}

/// Парсит текст на блоки: текстовые и математические ($$...$$).
List<_ContentBlock> _parseChatBlocks(String input) {
  final blocks = <_ContentBlock>[];
  final regex = RegExp(r'\$\$([\s\S]*?)\$\$');
  int lastEnd = 0;

  for (final match in regex.allMatches(input)) {
    if (match.start > lastEnd) {
      blocks.add(_ContentBlock(input.substring(lastEnd, match.start), false));
    }
    blocks.add(_ContentBlock(match.group(1)!, true));
    lastEnd = match.end;
  }

  if (lastEnd < input.length) {
    blocks.add(_ContentBlock(input.substring(lastEnd), false));
  }

  return blocks;
}

class _ContentBlock {
  final String content;
  final bool isMath;
  const _ContentBlock(this.content, this.isMath);
}

MarkdownStyleSheet _chatMarkdownStyle(Color textColor, bool isDark) {
  return MarkdownStyleSheet(
    p: TextStyle(fontSize: 14, color: textColor, height: 1.4),
    strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
    em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
    h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
    h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
    h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
    listBullet: TextStyle(fontSize: 14, color: textColor),
    code: TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      color: textColor,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
    ),
  );
}

/// Конвертирует инлайн-формулы $...$ в backtick-code `...` для обработки Math builder.
String _convertInlineMathToCode(String input) {
  return input.replaceAllMapped(
    RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)'),
    (m) => '`${m.group(1)}`',
  );
}

/// Builder для инлайн-кода в чате: рендерит LaTeX-формулы, остальное — обычный код.
class _ChatMathBuilder extends MarkdownElementBuilder {
  final Color textColor;
  final bool isDark;

  _ChatMathBuilder({required this.textColor, required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    if (_looksLikeLaTeX(code)) {
      try {
        return Math.tex(
          code,
          textStyle: TextStyle(fontSize: 14, color: textColor),
          mathStyle: MathStyle.text,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _looksLikeLaTeX(String s) {
    return s.contains('\\') ||
        s.contains('^') ||
        s.contains('_') ||
        s.contains('{') ||
        s.contains('\\frac') ||
        s.contains('\\sum') ||
        s.contains('\\int');
  }
}
