import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'app_theme.dart';

/// Управление темой приложения (только светлая/тёмная, без системной)
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color? _accentColor;

  ThemeMode get themeMode => _themeMode;
  Color? get accentColor => _accentColor;

  ThemeNotifier() {
    _themeMode = SettingsService.getThemeMode();
    _accentColor = SettingsService.getAccentColor();
  }

  void setThemeMode(ThemeMode mode) {
    // Только light или dark, без system
    final resolved = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == resolved) return;
    _themeMode = resolved;
    SettingsService.setThemeMode(resolved);
    notifyListeners();
  }

  void setAccentColor(Color? color) {
    if (_accentColor?.toARGB32() == color?.toARGB32()) return;
    _accentColor = color;
    SettingsService.setAccentColor(color);
    // Акцент вшит в обе темы — кеш под старый цвет больше не годится.
    _cachedLight = null;
    _cachedDark = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Кеш тем
  // ---------------------------------------------------------------------------
  //
  // `AppTheme.light/dark` внутри создают `ThemeData(useMaterial3: true)` —
  // конструктор недешёвый (типографика, дефолты всех под-тем), а поверх идёт
  // `copyWith` ещё с десятком тем. Обе строились заново на каждый build
  // `Consumer<ThemeNotifier>` в main.dart, то есть на каждый тап по кружку
  // акцентного цвета: два полных `ThemeData` плюс перестроение всего дерева,
  // потому что `Theme.of` возвращал новый экземпляр. Отсюда и заметная
  // задержка отрисовки на экране настроек.
  //
  // Теперь тема строится один раз на значение акцента и переживает любое
  // число перестроений; кеш сбрасывается только при смене цвета.

  ThemeData? _cachedLight;
  ThemeData? _cachedDark;

  ThemeData lightTheme() =>
      _cachedLight ??= AppTheme.light(accentColor: _accentColor);

  ThemeData darkTheme() =>
      _cachedDark ??= AppTheme.dark(accentColor: _accentColor);
}
