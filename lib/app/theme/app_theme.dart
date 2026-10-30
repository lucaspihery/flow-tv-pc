import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0E0F13);
  static const surface = Color(0xFF16181F);
  static const surfaceHigh = Color(0xFF1F222B);
  static const accent = Color(0xFF6C5CE7);
  static const textMuted = Color(0xFF9097A6);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(primary: AppColors.accent, surface: AppColors.surface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Segoe UI',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
  );
}
