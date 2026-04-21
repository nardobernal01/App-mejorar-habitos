import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/habit_provider.dart';
import 'screens/habit_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();

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

  // 1. Añadimos BuildContext para poder leer el tema del celular
  ThemeData _buildTheme(AppThemeMode mode, BuildContext context) {
    // MAGIA: Si el usuario tiene "Sistema", leemos si el celular está en modo oscuro
    if (mode == AppThemeMode.system) {
      final isDeviceDark =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      mode = isDeviceDark ? AppThemeMode.dark : AppThemeMode.light;
    }

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
      default:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F7F9),
          cardColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
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
      title: 'Bloom Your Day',
      debugShowCheckedModeBanner: false,

      // 2. Le pasamos el currentMode directamente a theme y quitamos los demás
      theme: _buildTheme(currentMode, context),

      home: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          if (!provider.isAuthenticated) {
            return const LoginScreen();
          }
          if (!hasSeenOnboarding) {
            return const OnboardingScreen();
          }
          if (provider.useBiometrics && !provider.isUnlocked) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      size: 80,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "App Protegida",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: provider.unlockAppWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text(
                        "Desbloquear",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const HabitScreen();
        },
      ),
    );
  }
}
