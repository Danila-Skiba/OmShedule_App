import 'package:flutter/material.dart';

abstract class PrefsKeys {
  static const themeMode = 'theme_mode';
  static const accentColorValue = 'accent_color_value';
  static const profileRole = 'profile_role';
  static const defaultGroupId = 'default_group_id';
  static const defaultTeacherId = 'default_teacher_id';
}

class SettingsService {
  static final Map<String, Object> _store = {};

  static void init() {
    // Значения по умолчанию при первом запуске
    _store.putIfAbsent(PrefsKeys.themeMode, () => 'light');
    _store.putIfAbsent(PrefsKeys.profileRole, () => 'student');
  }

  static ThemeMode getThemeMode() {
    final v = _store[PrefsKeys.themeMode] as String? ?? 'light';
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  static void setThemeMode(ThemeMode mode) {
    _store[PrefsKeys.themeMode] = mode == ThemeMode.dark ? 'dark' : 'light';
  }

  static Color? getAccentColor() {
    final v = _store[PrefsKeys.accentColorValue] as int?;
    return v != null ? Color(v) : null;
  }

  static void setAccentColor(Color? color) {
    if (color == null) {
      _store.remove(PrefsKeys.accentColorValue);
    } else {
      _store[PrefsKeys.accentColorValue] = color.value;
    }
  }

  static String getProfileRole() => _store[PrefsKeys.profileRole] as String? ?? 'student';
  static void setProfileRole(String role) => _store[PrefsKeys.profileRole] = role;

  static String? getDefaultGroupId() => _store[PrefsKeys.defaultGroupId] as String?;
  static void setDefaultGroupId(String? id) {
    if (id == null) {
      _store.remove(PrefsKeys.defaultGroupId);
    } else {
      _store[PrefsKeys.defaultGroupId] = id;
    }
  }

  static String? getDefaultTeacherId() => _store[PrefsKeys.defaultTeacherId] as String?;
  static void setDefaultTeacherId(String? id) {
    if (id == null) {
      _store.remove(PrefsKeys.defaultTeacherId);
    } else {
      _store[PrefsKeys.defaultTeacherId] = id;
    }
  }
}
