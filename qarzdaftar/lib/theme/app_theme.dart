import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D6EFD);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color bg = Color(0xFFF7F8FA);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  static const List<Color> avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF84CC16),
  ];

  static Color avatarColorFor(String key) {
    final hash = key.codeUnits.fold<int>(0, (a, b) => a + b);
    return avatarColors[hash % avatarColors.length];
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkCardBg,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: darkCardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkCardBg,
          selectedItemColor: primary,
          unselectedItemColor: darkTextSecondary,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
