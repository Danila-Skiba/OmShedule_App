import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headlineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.bold,   color: AppColors.textPrimary);
  static const TextStyle headlineMedium= TextStyle(fontSize: 20, fontWeight: FontWeight.bold,   color: AppColors.textPrimary);
  static const TextStyle headlineSmall = TextStyle(fontSize: 18, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const TextStyle titleMedium   = TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const TextStyle titleSmall    = TextStyle(fontSize: 14, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const TextStyle bodyLarge     = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static const TextStyle bodyMedium    = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static const TextStyle bodySmall     = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static const TextStyle caption       = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static const TextStyle label         = TextStyle(fontSize: 12, fontWeight: FontWeight.w600,   color: AppColors.textSecondary);
  static const TextStyle labelLarge    = TextStyle(fontSize: 14, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
}

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Светлая тема
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData light({Color? accentColor}) {
    final primary = accentColor ?? AppColors.primary;
    final primaryLight = accentColor != null
        ? Color.lerp(accentColor, Colors.white, 0.3) ?? AppColors.primaryLight
        : AppColors.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: AppColors.card,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.backgroundAlt,
        outline: AppColors.border,
      ),
      cardColor: AppColors.card,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTextStyles.headlineSmall.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.label,
        labelLarge: AppTextStyles.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected) ? primary : AppColors.divider;
        }),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Тёмная тема
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData dark({Color? accentColor}) {
    // В тёмной теме используем более яркий оттенок акцента
    final primary = accentColor != null
        ? Color.lerp(accentColor, Colors.white, 0.15) ?? AppColors.primaryDark
        : AppColors.primaryDark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: AppColors.primaryLightDark,
        surface: AppColors.cardDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        onError: Colors.white,
        outline: AppColors.borderDark,
        surfaceContainerHighest: AppColors.backgroundAltDark,
      ),
      cardColor: AppColors.cardDark,
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dividerColor: AppColors.dividerDark,

      // AppBar — почти чёрный фон, белый текст
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headlineSmall
            .copyWith(color: AppColors.textPrimaryDark),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimaryDark),
      ),

      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: TextTheme(
        headlineLarge:  AppTextStyles.headlineLarge .copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall:  AppTextStyles.headlineSmall .copyWith(color: AppColors.textPrimaryDark),
        titleMedium:    AppTextStyles.titleMedium   .copyWith(color: AppColors.textPrimaryDark),
        titleSmall:     AppTextStyles.titleSmall    .copyWith(color: AppColors.textPrimaryDark),
        bodyLarge:      AppTextStyles.bodyLarge     .copyWith(color: AppColors.textPrimaryDark),
        bodyMedium:     AppTextStyles.bodyMedium    .copyWith(color: AppColors.textPrimaryDark),
        bodySmall:      AppTextStyles.bodySmall     .copyWith(color: AppColors.textSecondaryDark),
        labelSmall:     AppTextStyles.label         .copyWith(color: AppColors.textSecondaryDark),
        labelLarge:     AppTextStyles.labelLarge    .copyWith(color: AppColors.textPrimaryDark),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? primary
              : AppColors.borderDark;
        }),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            return s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.22)
                : AppColors.backgroundAltDark;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            return s.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textSecondaryDark;
          }),
          side: WidgetStateProperty.all(
              const BorderSide(color: AppColors.borderDark)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardElevatedDark,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.titleMedium
            .copyWith(color: AppColors.textPrimaryDark),
        contentTextStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.textPrimaryDark),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardElevatedDark,
        contentTextStyle:
            TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
        actionTextColor: AppColors.primaryDark,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.cardElevatedDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        textStyle: const TextStyle(
            color: AppColors.textPrimaryDark, fontSize: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primary),
          overlayColor:
              WidgetStateProperty.all(primary.withValues(alpha: 0.1)),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
    );
  }
}
