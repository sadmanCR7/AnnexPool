import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB); // Premium Blue
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF0F172A);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF0F172A);
    const darkSurface = Color(0xFF1E293B);
    const darkTextPrimary = Color(0xFFF8FAFC);
    const darkTextSecondary = Color(0xFF94A3B8);

    final base = ThemeData.dark();

    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(color: darkTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: darkTextPrimary, fontSize: 16),
        bodyMedium: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    
    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(color: textPrimaryColor, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textPrimaryColor, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(color: textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium: const TextStyle(color: textSecondaryColor, fontSize: 14),
      ).apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
    );
  }
}
