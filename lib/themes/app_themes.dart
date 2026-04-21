import 'package:flutter/material.dart';
import '../providers/habit_provider.dart';

class AppThemes {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF2563EB),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          cardColor: Colors.white,
          useMaterial3: true,
        );
      case AppThemeMode.dark:
        return ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF3B82F6),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardColor: const Color(0xFF1E293B),
          useMaterial3: true,
        );
      case AppThemeMode.dracula:
        return ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFBD93F9),
          scaffoldBackgroundColor: const Color(0xFF282A36),
          cardColor: const Color(0xFF44475A),
          useMaterial3: true,
        );
      case AppThemeMode.forest:
        return ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF10B981),
          scaffoldBackgroundColor: const Color(0xFF064E3B),
          cardColor: const Color(0xFF065F46),
          useMaterial3: true,
        );
      // Añade aquí el resto de los 11 temas siguiendo este patrón
      default:
        return ThemeData(brightness: Brightness.light, useMaterial3: true);
    }
  }
}
