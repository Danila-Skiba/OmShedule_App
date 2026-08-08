import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PrefsKeys {
  static const themeMode = 'theme_mode';
  static const accentColorValue = 'accent_color_value';
  static const profileRole = 'profile_role';
  static const defaultGroupId = 'default_group_id';
  static const defaultTeacherId = 'default_teacher_id';
  // Сохранение последнего выбранного фильтра расписания
  static const lastFilterType = 'last_filter_type';   // 'group'|'teacher'|'audience'|'personal'
  static const lastGroupId = 'last_group_id';
  static const lastTeacherId = 'last_teacher_id';
  static const lastAudienceId = 'last_audience_id';

  /// Префикс времени последнего обновления справочника: к нему добавляется
  /// ключ справочника (`groups`, `persons`, `auditories`).
  static const directoryUpdatedAtPrefix = 'directory_updated_at_';
}

class SettingsService {
  static late SharedPreferences _prefs;

  /// Вызвать один раз в main() перед runApp.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static ThemeMode getThemeMode() {
    final v = _prefs.getString(PrefsKeys.themeMode) ?? 'light';
    return v == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static void setThemeMode(ThemeMode mode) {
    _prefs.setString(
        PrefsKeys.themeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Color? getAccentColor() {
    final v = _prefs.getInt(PrefsKeys.accentColorValue);
    return v != null ? Color(v) : null;
  }

  static void setAccentColor(Color? color) {
    if (color == null) {
      _prefs.remove(PrefsKeys.accentColorValue);
    } else {
      _prefs.setInt(PrefsKeys.accentColorValue, color.toARGB32());
    }
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  static String getProfileRole() =>
      _prefs.getString(PrefsKeys.profileRole) ?? 'student';

  static void setProfileRole(String role) =>
      _prefs.setString(PrefsKeys.profileRole, role);

  static String? getDefaultGroupId() =>
      _prefs.getString(PrefsKeys.defaultGroupId);

  static void setDefaultGroupId(String? id) {
    if (id == null) {
      _prefs.remove(PrefsKeys.defaultGroupId);
    } else {
      _prefs.setString(PrefsKeys.defaultGroupId, id);
    }
  }

  static String? getDefaultTeacherId() =>
      _prefs.getString(PrefsKeys.defaultTeacherId);

  static void setDefaultTeacherId(String? id) {
    if (id == null) {
      _prefs.remove(PrefsKeys.defaultTeacherId);
    } else {
      _prefs.setString(PrefsKeys.defaultTeacherId, id);
    }
  }

  // ---------------------------------------------------------------------------
  // Последний выбранный фильтр расписания
  // ---------------------------------------------------------------------------

  static String getLastFilterType() =>
      _prefs.getString(PrefsKeys.lastFilterType) ?? 'group';

  static void setLastFilterType(String type) =>
      _prefs.setString(PrefsKeys.lastFilterType, type);

  static String? getLastGroupId() => _prefs.getString(PrefsKeys.lastGroupId);
  static void setLastGroupId(String? id) {
    if (id == null) {
      _prefs.remove(PrefsKeys.lastGroupId);
    } else {
      _prefs.setString(PrefsKeys.lastGroupId, id);
    }
  }

  static String? getLastTeacherId() =>
      _prefs.getString(PrefsKeys.lastTeacherId);

  static void setLastTeacherId(String? id) {
    if (id == null) {
      _prefs.remove(PrefsKeys.lastTeacherId);
    } else {
      _prefs.setString(PrefsKeys.lastTeacherId, id);
    }
  }

  // ---------------------------------------------------------------------------
  // Обновление справочников
  // ---------------------------------------------------------------------------

  /// Когда справочник обновлялся в последний раз (null — ни разу).
  static DateTime? getDirectoryUpdatedAt(String directoryKey) {
    final raw =
        _prefs.getString('${PrefsKeys.directoryUpdatedAtPrefix}$directoryKey');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static void setDirectoryUpdatedAt(String directoryKey, DateTime at) {
    _prefs.setString(
      '${PrefsKeys.directoryUpdatedAtPrefix}$directoryKey',
      at.toIso8601String(),
    );
  }

  static String? getLastAudienceId() =>
      _prefs.getString(PrefsKeys.lastAudienceId);

  static void setLastAudienceId(String? id) {
    if (id == null) {
      _prefs.remove(PrefsKeys.lastAudienceId);
    } else {
      _prefs.setString(PrefsKeys.lastAudienceId, id);
    }
  }
}
