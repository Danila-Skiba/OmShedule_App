import 'package:flutter/material.dart';

/// Базовые цвета приложения (primary, secondary, background, surface, text)
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundAlt = Color(0xFFF1F5F9);

  // Primary & Secondary
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);

  //Hint (light)
  static const Color hintprimary = Color.fromARGB(255, 226, 233, 255);
  static const Color hintwarning = Color.fromARGB(255, 255, 244, 227);
  static const Color hinterror = Color.fromARGB(255, 255, 231, 229);
  static const Color hintsuccess = Color.fromARGB(255, 228, 255, 229);

  //Hint (dark)
  static const Color hintprimaryDark = Color(0xFF1A2540);
  static const Color hintwarningDark = Color(0xFF2A2010);
  static const Color hinterrorDark = Color(0xFF2A1515);
  static const Color hintsuccessDark = Color(0xFF152A1A);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color.fromARGB(255, 255, 168, 19);
  static const Color error = Color(0xFFEF4444);

  // UI
  static const Color border = Color(0xFFE2E8F0);
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFCBD5E1);

  // Dark theme (приятные тёмные тона, без резкого контраста)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundAltDark = Color(0xFF1E1E1E);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE4E4E7);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color borderDark = Color(0xFF2C2C2E);
  static const Color dividerDark = Color(0xFF3F3F46);
}
