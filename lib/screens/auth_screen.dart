import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_config.dart';
import '../core/services/auth_service.dart';
import '../widgets/app_snackbar.dart';

/// Экран авторизации / регистрации.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  bool _loading = false;
  int _pageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      AppSnackBar.error(context, 'Заполните все поля');
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService.instance.login(email, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      AppSnackBar.success(context, 'Вы вошли в аккаунт');
      Navigator.of(context).pop(true);
    } else {
      AppSnackBar.error(context, error);
    }
  }

  Future<void> _doTelegramLogin() async {
    setState(() => _loading = true);

    try {
      // 1. Запросить state и bot_url
      final initUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authTelegramInit}');
      final initResp = await http.post(initUrl);

      if (!mounted) return;

      if (initResp.statusCode != 200) {
        setState(() => _loading = false);
        AppSnackBar.error(context, 'Не удалось инициализировать вход через Telegram');
        return;
      }

      final initJson = jsonDecode(initResp.body) as Map<String, dynamic>;
      final state = initJson['state'] as String;
      final botUrl = initJson['bot_url'] as String;

      // 2. Открыть Telegram
      final uri = Uri.parse(botUrl);
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        if (!mounted) return;
        setState(() => _loading = false);
        AppSnackBar.error(context, 'Telegram не установлен');
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;
      setState(() => _loading = false);

      // 3. Показать диалог ожидания с поллингом
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TelegramPollingDialog(state: state),
      );

      if (success == true && mounted) {
        AppSnackBar.success(context, 'Вы вошли через Telegram');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackBar.error(context, 'Ошибка сети');
    }
  }

  Future<void> _doRegister() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      AppSnackBar.error(context, 'Заполните все поля');
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService.instance.register(name, email, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      AppSnackBar.success(context, 'Регистрация успешна');
      Navigator.of(context).pop(true);
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Аккаунт')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Логотип
          _OmgtuLogo(color: primary, size: 72),
          const SizedBox(height: 20),
          // Свитчер
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSegmentedControl(theme, isDark, primary, onSurface),
          ),
          const SizedBox(height: 8),
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              children: [
                _buildLoginPage(theme, isDark, primary, onSurface),
                _buildRegisterPage(theme, isDark, primary, onSurface),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(
      ThemeData theme, bool isDark, Color primary, Color onSurface) {
    final activeBg =
        isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final containerBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : primary.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : primary.withValues(alpha: 0.1),
        ),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(
                left: _pageIndex == 0 ? 0 : constraints.maxWidth / 2,
              ),
              width: constraints.maxWidth / 2,
              height: 38,
              decoration: BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
            ),
            Row(
              children: [
                _segmentBtn('Вход', 0, isDark, theme),
                _segmentBtn('Регистрация', 1, isDark, theme),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _segmentBtn(
      String label, int index, bool isDark, ThemeData theme) {
    final isSelected = _pageIndex == index;
    final textColor = isDark
        ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.45))
        : (isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.5));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _goToPage(index),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPage(
      ThemeData theme, bool isDark, Color primary, Color onSurface) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Войти в аккаунт',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Для доступа к конспектам лекций',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          _buildTextField(_loginEmailCtrl, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildTextField(
              _loginPassCtrl, 'Пароль', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 28),
          _buildPrimaryButton('Войти', _loading ? null : _doLogin),
          const SizedBox(height: 14),
          _buildTelegramButton(isDark),
        ],
      ),
    );
  }

  Widget _buildRegisterPage(
      ThemeData theme, bool isDark, Color primary, Color onSurface) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Создать аккаунт',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Быстрая регистрация',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          _buildTextField(
              _regNameCtrl, 'Имя', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildTextField(_regEmailCtrl, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildTextField(
              _regPassCtrl, 'Пароль', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 28),
          _buildPrimaryButton(
              'Зарегистрироваться', _loading ? null : _doRegister),
          const SizedBox(height: 14),
          _buildTelegramButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : theme.colorScheme.primary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTelegramButton(bool isDark) {
    const tgColor = Color(0xFF2AABEE);
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _doTelegramLogin,
        icon: const Icon(Icons.send_rounded, size: 20),
        label: const Text('Войти через Telegram'),
        style: OutlinedButton.styleFrom(
          foregroundColor: tgColor,
          side: BorderSide(
            color: tgColor.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: _loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// =============================================================================
// Диалог ожидания авторизации через Telegram (поллинг)
// =============================================================================

class _TelegramPollingDialog extends StatefulWidget {
  final String state;

  const _TelegramPollingDialog({required this.state});

  @override
  State<_TelegramPollingDialog> createState() => _TelegramPollingDialogState();
}

class _TelegramPollingDialogState extends State<_TelegramPollingDialog> {
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _polling = true;
  String? _error;
  int _elapsed = 0; // секунды

  static const _pollInterval = Duration(seconds: 2);
  static const _timeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Таймаут через 5 минут
    _timeoutTimer = Timer(_timeout, () {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _polling = false;
          _error = 'Время ожидания истекло. Попробуйте снова.';
        });
      }
    });

    // Счётчик секунд для отображения
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_polling) {
        t.cancel();
        return;
      }
      setState(() => _elapsed++);
    });

    // Поллинг каждые 2 секунды
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkToken());
  }

  Future<void> _checkToken() async {
    if (!_polling || !mounted) return;

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.authTelegramToken}?state=${widget.state}',
      );
      final resp = await http.get(url);

      if (!mounted || !_polling) return;

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final ready = json['ready'] == true;

        if (ready) {
          _pollTimer?.cancel();
          _timeoutTimer?.cancel();
          setState(() => _polling = false);

          final accessToken = json['access_token'] as String;
          final error = await AuthService.instance.loginWithToken(accessToken);

          if (!mounted) return;

          if (error == null) {
            Navigator.of(context).pop(true);
          } else {
            setState(() => _error = error);
          }
        }
      }
    } catch (e) {
      // Молча продолжаем поллинг — сеть может временно быть недоступна
    }
  }

  void _cancel() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  String get _formattedElapsed {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    const tgColor = Color(0xFF2AABEE);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: _error != null
                  ? Icon(Icons.error_outline_rounded, size: 32, color: Colors.red.shade400)
                  : const Icon(Icons.send_rounded, size: 28, color: tgColor),
            ),
            const SizedBox(height: 20),

            // Заголовок
            Text(
              _error != null
                  ? 'Ошибка'
                  : _polling
                      ? 'Ожидание авторизации'
                      : 'Подключение...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Подзаголовок
            Text(
              _error ??
                  'Подтвердите вход в боте Telegram.\nОкно закроется автоматически.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Индикатор / таймер
            if (_polling) ...[
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tgColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formattedElapsed,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Кнопки
            if (_error != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _cancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Закрыть'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface.withValues(alpha: 0.6),
                    side: BorderSide(
                      color: onSurface.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Логотип ОмГТУ — рисуется через CustomPainter, цвет адаптируется к теме
// =============================================================================

class _OmgtuLogo extends StatelessWidget {
  final Color color;
  final double size;

  const _OmgtuLogo({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 18,
      child: CustomPaint(
        painter: _OmgtuLogoPainter(color: color),
      ),
    );
  }
}

class _OmgtuLogoPainter extends CustomPainter {
  final Color color;

  _OmgtuLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    final bodyTop = s * 0.15;
    final bodyBottom = s * 0.88;
    final bodyLeft = s * 0.08;
    final bodyRight = s * 0.92;
    final r = s * 0.1; // corner radius

    // Тело календаря (скруглённый прямоугольник)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom),
      Radius.circular(r),
    );
    canvas.drawRRect(bodyRect, strokePaint);

    // Верхние «скобы» календаря
    final pinY1 = s * 0.04;
    final pinY2 = s * 0.22;
    final pinW = s * 0.04;
    final pinR = pinW;

    // Левая скоба
    final pin1X = bodyLeft + (bodyRight - bodyLeft) * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(pin1X, (pinY1 + pinY2) / 2),
            width: pinW,
            height: pinY2 - pinY1),
        Radius.circular(pinR),
      ),
      paint,
    );

    // Правая скоба
    final pin2X = bodyLeft + (bodyRight - bodyLeft) * 0.72;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(pin2X, (pinY1 + pinY2) / 2),
            width: pinW,
            height: pinY2 - pinY1),
        Radius.circular(pinR),
      ),
      paint,
    );

    // Сетка 3×3
    final gridLeft = bodyLeft + s * 0.1;
    final gridRight = bodyRight - s * 0.1;
    final gridTop = bodyTop + s * 0.2;
    final gridBottom = bodyBottom - s * 0.08;
    final cellW = (gridRight - gridLeft - s * 0.06) / 3;
    final cellH = (gridBottom - gridTop - s * 0.06) / 3;
    final gap = s * 0.03;
    final cellR = s * 0.03;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = gridLeft + col * (cellW + gap);
        final y = gridTop + row * (cellH + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellW, cellH),
            Radius.circular(cellR),
          ),
          paint,
        );
      }
    }

    // Текст «ОМГТУ»
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ОМГТУ',
        style: TextStyle(
          fontSize: s * 0.17,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: s * 0.02,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        bodyBottom + s * 0.04,
      ),
    );
  }

  @override
  bool shouldRepaint(_OmgtuLogoPainter oldDelegate) =>
      color != oldDelegate.color;
}
