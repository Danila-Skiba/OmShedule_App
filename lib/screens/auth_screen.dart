import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../widgets/app_snackbar.dart';

/// Экран авторизации / регистрации.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: const Text('Аккаунт'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: onSurface.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Вход'),
            Tab(text: 'Регистрация'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Вход ──
          _buildLoginTab(theme, isDark, primary, onSurface),
          // ── Регистрация ──
          _buildRegisterTab(theme, isDark, primary, onSurface),
        ],
      ),
    );
  }

  Widget _buildLoginTab(ThemeData theme, bool isDark, Color primary, Color onSurface) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.school_rounded, size: 64, color: primary.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
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
          const SizedBox(height: 32),
          _buildTextField(_loginEmailCtrl, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildTextField(_loginPassCtrl, 'Пароль', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 28),
          _buildPrimaryButton('Войти', _loading ? null : _doLogin),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(ThemeData theme, bool isDark, Color primary, Color onSurface) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
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
          _buildTextField(_regNameCtrl, 'Имя', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildTextField(_regEmailCtrl, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildTextField(_regPassCtrl, 'Пароль', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 28),
          _buildPrimaryButton('Зарегистрироваться', _loading ? null : _doRegister),
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
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
