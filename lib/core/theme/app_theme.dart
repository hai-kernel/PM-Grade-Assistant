import 'package:flutter/material.dart';

class AppColors {
  // Background layers (Light & Fresh Educational Blue Theme)
  static const Color bg0 = Color(0xFFF0F4F8); // Deepest background (app shell)
  static const Color bg1 = Color(0xFFFFFFFF); // Main background
  static const Color bg2 = Color(0xFFF8FAFC); // Sidebar / panels
  static const Color bg3 = Color(0xFFFFFFFF); // Cards / elevated surfaces
  static const Color bg4 = Color(0xFFE2E8F0); // Hover states / inputs

  // Borders
  static const Color border0 = Color(0xFFE2E8F0);
  static const Color border1 = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Accent — Educational Blue (primary actions)
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF1D4ED8);
  static const Color accentBg = Color(0xFFDBEAFE);

  // Success — Green
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successBg = Color(0xFFD1FAE5);

  // Warning — Orange/Yellow
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningBg = Color(0xFFFEF3C7);

  // Danger — Red
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Purple — AI / System suggestions
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleBg = Color(0xFFEDE9FE);

  // Cyan — Info / public comment
  static const Color cyan = Color(0xFF0EA5E9);
  static const Color cyanBg = Color(0xFFE0F2FE);

  // Grading status colors
  static const Color graded = Color(0xFF10B981);
  static const Color ungraded = Color(0xFF94A3B8);
  static const Color inProgress = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.bg0,
      colorScheme: const ColorScheme.light(
        surface: AppColors.bg1,
        surfaceContainerHighest: AppColors.bg2,
        primary: AppColors.accent,
        secondary: AppColors.purple,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
      ),
      dividerColor: AppColors.border0,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        titleMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13),
        titleSmall: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14, height: 1.6),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 13, height: 1.5),
        bodySmall: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter', fontSize: 12, height: 1.5),
        labelLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 11),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bg3,
        shadowColor: Color(0x0A000000), // very soft shadow
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg2,
        hoverColor: AppColors.bg4,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accentLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border1),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter'),
      ),
    );
  }
}
