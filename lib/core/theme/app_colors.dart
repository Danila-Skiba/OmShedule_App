import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Светлая тема ────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF3F6FC);
  static const Color backgroundAlt = Color(0xFFEAEFF8);
  static const Color primary       = Color(0xFF1E3A8A);
  static const Color primaryLight  = Color(0xFF3B82F6);
  static const Color card          = Colors.white;
  static const Color border        = Color(0xFFE2E8F0);
  static const Color divider       = Color(0xFFCBD5E1);

  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error   = Color(0xFFF87171);

  static const Color taskAccent = Color(0xFFA78BFA);

  // Hint (light) — фон карточек занятий в светлой теме (пастельные)
  static const Color hintprimary = Color(0xFFE8F0FE);
  static const Color hintwarning = Color(0xFFFFF8E1);
  static const Color hinterror   = Color(0xFFFEECEC);
  static const Color hintsuccess = Color(0xFFE6FAF0);
  static const Color hintTask    = Color(0xFFF3EEFF);

  // Hint (dark) — фон карточки «Личное» в тёмной теме
  static const Color hintTaskDark = Color(0xFF1E1530);

  // ── Тёмная тема ─────────────────────────────────────────────────────────────
  // Фон
  static const Color backgroundDark    = Color(0xFF0D0D0D);
  static const Color backgroundAltDark = Color(0xFF161618);

  // Карточки
  static const Color cardDark         = Color(0xFF1C1C1E);
  static const Color cardElevatedDark = Color(0xFF242426);

  // Акцент
  static const Color primaryDark      = Color(0xFF4F95FF);
  static const Color primaryLightDark = Color(0xFF6AADFF);

  // Текст
  static const Color textPrimaryDark   = Color(0xFFF2F2F7);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textMutedDark     = Color(0xFF636366);

  // Границы
  static const Color borderDark  = Color(0xFF2C2C2E);
  static const Color dividerDark = Color(0xFF38383A);

  // Hint (dark) — тёмные фоны карточек занятий (мягкие)
  static const Color hintprimaryDark = Color(0xFF1A2744);
  static const Color hintwarningDark = Color(0xFF2A2210);
  static const Color hinterrorDark   = Color(0xFF2E1515);
  static const Color hintsuccessDark = Color(0xFF102A1C);
}
