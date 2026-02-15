import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ключи SharedPreferences
abstract class PrefsKeys {
  static const themeMode = 'theme_mode'; // light, dark, system
  static const accentColorValue = 'accent_color_value'; // int (Color.value)
  static const profileRole = 'profile_role'; // student, teacher
  static const defaultGroupId = 'default_group_id';
  static const defaultTeacherId = 'default_teacher_id';
}

/// Сервис настроек (тема, профиль)
class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) throw StateError('SettingsService.init() not called');
    return _prefs!;
  }

  static ThemeMode getThemeMode() {
    final v = prefs.getString(PrefsKeys.themeMode) ?? 'system';
    switch (v) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final v = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
    await prefs.setString(PrefsKeys.themeMode, v);
  }

  static Color? getAccentColor() {
    final v = prefs.getInt(PrefsKeys.accentColorValue);
    return v != null ? Color(v) : null;
  }

  static Future<void> setAccentColor(Color? color) async {
    if (color == null) {
      await prefs.remove(PrefsKeys.accentColorValue);
    } else {
      await prefs.setInt(PrefsKeys.accentColorValue, color.value);
    }
  }

  static String getProfileRole() => prefs.getString(PrefsKeys.profileRole) ?? 'student';
  static Future<void> setProfileRole(String role) => prefs.setString(PrefsKeys.profileRole, role);

  static String? getDefaultGroupId() => prefs.getString(PrefsKeys.defaultGroupId);
  static Future<void> setDefaultGroupId(String? id) async {
    if (id == null) {
      await prefs.remove(PrefsKeys.defaultGroupId);
    } else {
      await prefs.setString(PrefsKeys.defaultGroupId, id);
    }
  }

  static String? getDefaultTeacherId() => prefs.getString(PrefsKeys.defaultTeacherId);
  static Future<void> setDefaultTeacherId(String? id) async {
    if (id == null) {
      await prefs.remove(PrefsKeys.defaultTeacherId);
    } else {
      await prefs.setString(PrefsKeys.defaultTeacherId, id);
    }
  }
}
