import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'providers/habit_provider.dart';
import 'screens/login_screen.dart';
import 'screens/habit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  // Asumimos que si ya vio el Onboarding y está registrado, va directo a HabitScreen
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HabitProvider())],
      child: BloomYourDayApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class BloomYourDayApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const BloomYourDayApp({super.key, required this.hasSeenOnboarding});

  ThemeData _buildTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F7F9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          cardColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.dark:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          cardColor: const Color(0xFF1E293B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.amoled:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          cardColor: const Color(0xFF111111),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.dracula:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF282A36),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFFF8F8F2),
          ),
          cardColor: const Color(0xFF44475A),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF79C6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.forest:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1B2419),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFFD3E0CD),
          ),
          cardColor: const Color(0xFF2A3827),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA3B18A),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.teaBronze:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFEFAE0),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          cardColor: const Color(0xFFFAEDCD),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD4A373),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.pastelSky:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFBDE0FE),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          cardColor: const Color(0xFFFFC8DD),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA2D2FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.emeraldOcean:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF073B4C),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          cardColor: const Color(0xFF118AB2),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF06D6A0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.frostedMint:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFCF6BD),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          cardColor: const Color(0xFFD0F4DE),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA9DEF9),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeMode.watercolor:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFFFFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          cardColor: const Color(0xFFFDFFB6),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFBDB2FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = context.watch<HabitProvider>().currentTheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bloom Your Day',
      theme: _buildTheme(currentMode),
      home: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: hasSeenOnboarding ? const HabitScreen() : const LoginScreen(),
      ),
    );
  }
}
