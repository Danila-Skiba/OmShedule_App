import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/lecture_api_service.dart';
import '../widgets/base_container.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import 'lecture_chat_screen.dart';
import 'markdown_viewer_screen.dart';

/// Экран «Конспекты» — активные и завершённые сессии из API.
class LectureNotesScreen extends StatefulWidget {
  const LectureNotesScreen({super.key});

  @override
  State<LectureNotesScreen> createState() => _LectureNotesScreenState();
}

class _LectureNotesScreenState extends State<LectureNotesScreen> {
  List<ApiLectureSession> _activeSessions = [];
  List<ApiLectureSession> _compiledSessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!AuthService.instance.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await LectureApiService.instance.getAllSessions();
      if (!mounted) return;
      setState(() {
        _activeSessions = sessions.where((s) => !s.isCompiled).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _compiledSessions = sessions.where((s) => s.isCompiled).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        msg = 'Не удалось подключиться к серверу. Проверьте подключение к сети.';
      } else if (msg.contains('FormatException')) {
        msg = 'Некорректный ответ сервера.';
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  void _createNewSession() {
    final subjectCtrl = TextEditingController();

    AppDialog.show(
      context: context,
      icon: Icons.add_rounded,
      title: 'Новая сессия',
      confirmText: 'Создать',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: subjectCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Название предмета',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      onConfirm: () async {
        final subject = subjectCtrl.text.trim();
        if (subject.isEmpty) {
          AppSnackBar.error(context, 'Введите название предмета');
          return;
        }
        try {
          final session = await LectureApiService.instance.createSession(subject);
          if (!mounted) return;
          // Открываем чат
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => LectureChatScreen(
                sessionId: session.sessionId,
                subject: session.subject,
              ),
            ),
          ).then((_) => _loadSessions());
        } catch (e) {
          if (!mounted) return;
          AppSnackBar.error(context, 'Ошибка: $e');
        }
      },
    );
  }

  void _openSession(ApiLectureSession session) {
    if (session.isCompiled) {
      _openCompiled(session);
    } else {
      // Открываем чат для продолжения
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => LectureChatScreen(
            sessionId: session.sessionId,
            subject: session.subject,
          ),
        ),
      ).then((_) => _loadSessions());
    }
  }

  Future<void> _openCompiled(ApiLectureSession session) async {
    try {
      // Подгрузим полную сессию с md_content
      final full = await LectureApiService.instance.getSession(session.sessionId);
      if (!mounted) return;
      if (full.mdContent != null && full.mdContent!.isNotEmpty) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => MarkdownViewerScreen(
              title: full.subject,
              subtitle: _formatDate(full.compiledAt ?? full.createdAt),
              markdownContent: full.mdContent!,
            ),
          ),
        );
      } else {
        AppSnackBar.error(context, 'Конспект пуст');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Ошибка: $e');
    }
  }

  Future<void> _deleteSession(ApiLectureSession session) async {
    AppDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'Удалить сессию?',
      message: 'Сессия «${session.subject}» будет удалена без возможности восстановления.',
      confirmText: 'Удалить',
      isDestructive: true,
      onConfirm: () async {
        try {
          await LectureApiService.instance.deleteSession(session.sessionId);
          if (!mounted) return;
          AppSnackBar.success(context, 'Сессия удалена');
          _loadSessions();
        } catch (e) {
          if (!mounted) return;
          AppSnackBar.error(context, 'Ошибка: $e');
        }
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    if (diff.inDays < 7) return '${diff.inDays}д назад';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Конспекты')),
      floatingActionButton: auth.isAuthenticated
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                onPressed: _createNewSession,
                backgroundColor: primary,
                child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
              ),
            )
          : null,
      body: !auth.isAuthenticated
          ? _buildAuthPrompt(theme, primary, onSurface)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError(theme, onSurface)
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: _buildContent(theme, isDark, primary, onSurface),
                    ),
    );
  }

  Widget _buildAuthPrompt(ThemeData theme, Color primary, Color onSurface) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Войдите для использования конспектов',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Отправляйте фото лекций и получайте готовый конспект в формате Markdown',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Войти', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Color onSurface) {
    // Убираем лишние Exception(...) обёртки
    String displayError = _error ?? 'Неизвестная ошибка';
    displayError = displayError.replaceAll(RegExp(r'^Exception:\s*'), '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Ошибка загрузки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
            const SizedBox(height: 8),
            Text(
              displayError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark, Color primary, Color onSurface) {
    final hasActive = _activeSessions.isNotEmpty;
    final hasCompiled = _compiledSessions.isNotEmpty;

    if (!hasActive && !hasCompiled) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.note_add_rounded, size: 56, color: primary.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Нет конспектов',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Создайте первую сессию, нажав +',
                  style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (hasActive) ...[
          _sectionHeader('Активные', Icons.edit_note_rounded, primary),
          const SizedBox(height: 10),
          ...(_activeSessions.map((s) => _SessionCard(
                session: s,
                onTap: () => _openSession(s),
                onDelete: () => _deleteSession(s),
              ))),
          const SizedBox(height: 20),
        ],
        if (hasCompiled) ...[
          _sectionHeader('Завершённые', Icons.check_circle_outline_rounded, primary),
          const SizedBox(height: 10),
          ...(_compiledSessions.map((s) => _SessionCard(
                session: s,
                onTap: () => _openSession(s),
                onDelete: () => _deleteSession(s),
              ))),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Карточка сессии.
class _SessionCard extends StatelessWidget {
  final ApiLectureSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final timeStr = _formatTime(session.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BaseContainer(
        isGlass: isDark,
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              // Иконка статуса
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: session.isCompiled
                      ? Colors.green.withValues(alpha: 0.12)
                      : primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  session.isCompiled
                      ? Icons.description_rounded
                      : Icons.edit_rounded,
                  size: 20,
                  color: session.isCompiled ? Colors.green : primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Кнопки
              if (session.isCompiled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Открыть',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Продолжить',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays}д назад';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
