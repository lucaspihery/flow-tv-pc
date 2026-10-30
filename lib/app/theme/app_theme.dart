import 'package:flutter/material.dart';

/// Couleurs tirées du logo Flow TV : dégradé cyan → bleu → violet → magenta sur fond bleu nuit.
class AppColors {
  static const background = Color(0xFF02022E);
  static const surface = Color(0xFF0A0B40);
  static const surfaceHigh = Color(0xFF151758);
  static const textMuted = Color(0xFF9A9DCC);

  static const cyan = Color(0xFF1DE4FF);
  static const blue = Color(0xFF2D6BFF);
  static const violet = Color(0xFF7A1CFF);
  static const magenta = Color(0xFFFC58FD);

  /// Couleur d'accent principale (boutons, sélection).
  static const accent = Color(0xFF5B3BFF);

  /// Étoile des favoris.
  static const favorite = Color(0xFFFFC94D);

  static const brandGradient = LinearGradient(colors: [cyan, blue, violet, magenta]);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.accent, brightness: Brightness.dark).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.cyan,
    tertiary: AppColors.magenta,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Segoe UI',
    dividerColor: AppColors.surfaceHigh,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.cyan),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
  );
}
