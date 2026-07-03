import 'package:flutter/material.dart';

/// Цвета как в miniapp CleanApp.jsx (фиолетовая тема GPN).
final gpnDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0015),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFF7C3AED),
    surface: Color(0xFF12051F),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0015),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1A0B2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0x408B5CF6)),
    ),
  ),
);
