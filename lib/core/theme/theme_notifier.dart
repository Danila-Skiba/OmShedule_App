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
    notifyListeners();
  }

  ThemeData lightTheme() => AppTheme.light(accentColor: _accentColor);
  ThemeData darkTheme() => AppTheme.dark(accentColor: _accentColor);
}
