import 'package:flutter/material.dart';

/// YoldashMoto design system: minimal, calm, one-handed, night-friendly.
class YmColors {
  static const accent = Color(0xFFFF6B1A); // moto orange
  static const accentDark = Color(0xFFE55A0A);
  static const sos = Color(0xFFFF3B30);
  static const ok = Color(0xFF22C55E);
  static const night = Color(0xFF0B0E14);
  static const cardDark = Color(0xFF151B26);
  static const lineDark = Color(0xFF232C3D);
}

class YmTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: YmColors.accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: YmColors.accent,
          brightness: Brightness.dark,
        ).copyWith(surface: YmColors.night),
        scaffoldBackgroundColor: YmColors.night,
        cardTheme: CardThemeData(
          elevation: 0,
          color: YmColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: YmColors.lineDark),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
