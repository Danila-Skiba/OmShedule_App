import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'app_theme.dart';

/// Управление темой приложения (светлая/тёмная/системная + акцент)
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color? _accentColor;

  ThemeMode get themeMode => _themeMode;
  Color? get accentColor => _accentColor;

  ThemeNotifier() {
    _themeMode = SettingsService.getThemeMode();
    _accentColor = SettingsService.getAccentColor();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    SettingsService.setThemeMode(mode);
    notifyListeners();
  }

  void setAccentColor(Color? color) {
    if (_accentColor?.value == color?.value) return;
    _accentColor = color;
    SettingsService.setAccentColor(color);
    notifyListeners();
  }

  ThemeData lightTheme() => AppTheme.light(accentColor: _accentColor);
  ThemeData darkTheme() => AppTheme.dark(accentColor: _accentColor);
}
