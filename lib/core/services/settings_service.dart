import 'package:flutter/material.dart';

abstract class PrefsKeys {
  static const themeMode = 'theme_mode';
  static const accentColorValue = 'accent_color_value';
  static const profileRole = 'profile_role';
  static const defaultGroupId = 'default_group_id';
  static const defaultTeacherId = 'default_teacher_id';
  static const scheduleFilterType = 'schedule_filter_type';
  static const scheduleFilterGroupId = 'schedule_filter_group_id';
  static const scheduleFilterTeacherId = 'schedule_filter_teacher_id';
  static const scheduleFilterRoomId = 'schedule_filter_room_id';
}

class SettingsService {
  static final Map<String, Object> _store = {};

  static void init() {
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

  // --- Filter persistence ---
  static String? getScheduleFilterType() => _store[PrefsKeys.scheduleFilterType] as String?;
  static void setScheduleFilterType(String? type) {
    if (type == null) {
      _store.remove(PrefsKeys.scheduleFilterType);
    } else {
      _store[PrefsKeys.scheduleFilterType] = type;
    }
  }

  static String? getScheduleFilterGroupId() => _store[PrefsKeys.scheduleFilterGroupId] as String?;
  static void setScheduleFilterGroupId(String? id) {
    if (id == null) {
      _store.remove(PrefsKeys.scheduleFilterGroupId);
    } else {
      _store[PrefsKeys.scheduleFilterGroupId] = id;
    }
  }

  static String? getScheduleFilterTeacherId() => _store[PrefsKeys.scheduleFilterTeacherId] as String?;
  static void setScheduleFilterTeacherId(String? id) {
    if (id == null) {
      _store.remove(PrefsKeys.scheduleFilterTeacherId);
    } else {
      _store[PrefsKeys.scheduleFilterTeacherId] = id;
    }
  }

  static String? getScheduleFilterRoomId() => _store[PrefsKeys.scheduleFilterRoomId] as String?;
  static void setScheduleFilterRoomId(String? id) {
    if (id == null) {
      _store.remove(PrefsKeys.scheduleFilterRoomId);
    } else {
      _store[PrefsKeys.scheduleFilterRoomId] = id;
    }
  }
}
