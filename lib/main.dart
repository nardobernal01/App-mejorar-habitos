import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'models/habit_model.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart'; // NUEVO IMPORT
import 'providers/habit_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HabitProvider())],
      child: VitalHabitApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class VitalHabitApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const VitalHabitApp({super.key, required this.hasSeenOnboarding});

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
      title: 'VitalHabit',
      theme: _buildTheme(currentMode),
      home: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: hasSeenOnboarding
            ? const HabitScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _habitController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Color> _palette = [
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFF6366F1),
  ];

  final List<IconData> _iconList = [
    Icons.local_fire_department_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.water_drop_rounded,
    Icons.self_improvement_rounded,
    Icons.monitor_rounded,
    Icons.restaurant_rounded,
    Icons.cleaning_services_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _shareStats(HabitProvider provider) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File(
          '${directory.path}/vital_habit_stats.png',
        ).create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              '🔥 ¡Dominando mis hábitos en Nivel ${provider.playerLevel} con VitalHabit!',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al compartir')));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return "Buenas madrugadas";
    if (hour < 12) return "Buenos días";
    if (hour < 19) return "Buenas tardes";
    return "Buenas noches";
  }

  String _getDate() {
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final now = DateTime.now();
    return "${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}";
  }

  void _showProPaywall(HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 80,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 20),
              const Text(
                "VITALHABIT PRO",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Desbloquea 8 temas premium exclusivos, colores ilimitados y seguridad biométrica avanzada.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  SystemSound.play(SystemSoundType.alert);
                  provider.unlockPremium();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Felicidades! Eres usuario PRO 💎',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                },
                child: const Text(
                  "Desbloquear ahora (\$2.99/m)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Quizá más tarde",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = provider.isPremiumUnlocked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Apariencia",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Básicos (Gratis)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [AppThemeMode.light, AppThemeMode.dark].map((mode) {
                    return ChoiceChip(
                      label: Text(mode.name.toUpperCase()),
                      selected: provider.currentTheme == mode,
                      onSelected: (selected) {
                        SystemSound.play(SystemSoundType.click);
                        HapticFeedback.selectionClick();
                        context.read<HabitProvider>().setTheme(mode);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text(
                        "Colección Premium ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      if (!isPro)
                        const Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children:
                      [
                        AppThemeMode.amoled,
                        AppThemeMode.dracula,
                        AppThemeMode.forest,
                        AppThemeMode.teaBronze,
                        AppThemeMode.pastelSky,
                        AppThemeMode.emeraldOcean,
                        AppThemeMode.frostedMint,
                        AppThemeMode.watercolor,
                      ].map((mode) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isPro)
                                const Icon(Icons.lock_rounded, size: 14),
                              if (!isPro) const SizedBox(width: 4),
                              Text(mode.name.toUpperCase()),
                            ],
                          ),
                          selectedColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.3),
                          selected: provider.currentTheme == mode,
                          onSelected: (selected) {
                            SystemSound.play(SystemSoundType.click);
                            HapticFeedback.selectionClick();
                            if (isPro) {
                              context.read<HabitProvider>().setTheme(mode);
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);
                              _showProPaywall(provider);
                            }
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsModal(HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int totalCompletions = provider.myHabits.fold(
      0,
      (sum, habit) => sum + habit.streak,
    );
    int maxStreak = provider.myHabits.isEmpty
        ? 0
        : provider.myHabits
              .map((h) => h.streak)
              .reduce((a, b) => a > b ? a : b);
    double successRate = provider.myHabits.isEmpty
        ? 0
        : (provider.myHabits.where((h) => h.isCompleted).length /
                  provider.myHabits.length) *
              100;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tu Rendimiento",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFF2563EB),
                      ),
                      onPressed: () => _shareStats(provider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      "Tasa Éxito",
                      "${successRate.toInt()}%",
                      Icons.pie_chart_rounded,
                      const Color(0xFF10B981),
                      isDark,
                    ),
                    _buildStatCard(
                      "Racha Máxima",
                      "$maxStreak Días",
                      Icons.local_fire_department_rounded,
                      const Color(0xFFF59E0B),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      "Completados",
                      "$totalCompletions",
                      Icons.check_circle_rounded,
                      const Color(0xFF3B82F6),
                      isDark,
                    ),
                    _buildStatCard(
                      "Hábitos",
                      "${provider.myHabits.length}",
                      Icons.format_list_bulleted_rounded,
                      const Color(0xFF8B5CF6),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth
          ? double.infinity
          : MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitDialog({int? index}) {
    SystemSound.play(SystemSoundType.click);
    final provider = context.read<HabitProvider>();
    bool isEdit = index != null;
    _habitController.text = isEdit ? provider.myHabits[index].title : "";
    Color selectedColor = isEdit
        ? provider.myHabits[index].dynamicColor
        : _palette[0];
    IconData selectedIcon = isEdit
        ? IconData(
            provider.myHabits[index].iconCodePoint,
            fontFamily: 'MaterialIcons',
          )
        : _iconList[0];
    TimeOfDay? selectedReminder;

    if (isEdit && provider.myHabits[index].reminderTime != null) {
      final parts = provider.myHabits[index].reminderTime!.split(":");
      selectedReminder = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> quickActions = [
      {
        "label": "💧 Agua",
        "title": "Tomar 2L de agua",
        "color": _palette[1],
        "icon": _iconList[3],
        "time": null,
      },
      {
        "label": "🌅 Despertar",
        "title": "Levantarse temprano",
        "color": _palette[3],
        "icon": _iconList[0],
        "time": const TimeOfDay(hour: 6, minute: 0),
      },
      {
        "label": "🛌 Dormir",
        "title": "Hora de dormir",
        "color": _palette[7],
        "icon": _iconList[4],
        "time": const TimeOfDay(hour: 22, minute: 30),
      },
      {
        "label": "🍎 Comer",
        "title": "Comida saludable",
        "color": _palette[4],
        "icon": _iconList[6],
        "time": const TimeOfDay(hour: 14, minute: 0),
      },
      {
        "label": "💻 Programar",
        "title": "Estudiar Código",
        "color": _palette[2],
        "icon": _iconList[5],
        "time": const TimeOfDay(hour: 18, minute: 0),
      },
      {
        "label": "📖 Leer",
        "title": "Leer 15 minutos",
        "color": _palette[0],
        "icon": _iconList[2],
        "time": null,
      },
      {
        "label": "🏋️ Ejercicio",
        "title": "Hacer ejercicio",
        "color": _palette[6],
        "icon": _iconList[1],
        "time": null,
      },
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      barrierColor: Colors.black.withValues(alpha: 0.3),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleCurve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        ).value;
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0 * anim1.value,
            sigmaY: 5.0 * anim1.value,
          ),
          child: Transform.scale(
            scale: scaleCurve,
            child: FadeTransition(
              opacity: anim1,
              child: StatefulBuilder(
                builder: (context, setDS) => AlertDialog(
                  backgroundColor: Theme.of(
                    context,
                  ).cardColor.withValues(alpha: 0.95),
                  elevation: isDark ? 10 : 24,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? "Editar Hábito" : "Nuevo Hábito",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          selectedReminder != null
                              ? Icons.notifications_active_rounded
                              : Icons.notification_add_rounded,
                          color: selectedReminder != null
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedReminder ?? TimeOfDay.now(),
                            builder: (context, child) =>
                                Theme(data: Theme.of(context), child: child!),
                          );
                          if (time != null) {
                            setDS(() => selectedReminder = time);
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedReminder != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alarm_rounded,
                                    color: Color(0xFF10B981),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Alarma a las ${selectedReminder!.format(context)}",
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () =>
                                        setDS(() => selectedReminder = null),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          TextField(
                            controller: _habitController,
                            autofocus: !isEdit,
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 40,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: "Ej. Leer 10 páginas",
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.03),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: quickActions
                                  .map(
                                    (action) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ActionChip(
                                        label: Text(action["label"]),
                                        backgroundColor: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        side: BorderSide.none,
                                        onPressed: () {
                                          SystemSound.play(
                                            SystemSoundType.click,
                                          );
                                          HapticFeedback.mediumImpact();
                                          if (isEdit) {
                                            setDS(() {
                                              _habitController.text =
                                                  action["title"];
                                              selectedColor = action["color"];
                                              selectedIcon = action["icon"];
                                              if (action["time"] != null) {
                                                selectedReminder =
                                                    action["time"];
                                              }
                                            });
                                          } else {
                                            String? rStr =
                                                action["time"] != null
                                                ? "${action["time"].hour}:${action["time"].minute.toString().padLeft(2, '0')}"
                                                : null;
                                            provider.addOrUpdateHabit(
                                              action["title"],
                                              action["color"],
                                              action["icon"].codePoint,
                                              rStr,
                                            );
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Color",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemCount: _palette.length,
                            itemBuilder: (context, idx) {
                              final c = _palette[idx];
                              return GestureDetector(
                                onTap: () {
                                  SystemSound.play(SystemSoundType.click);
                                  HapticFeedback.selectionClick();
                                  setDS(() => selectedColor = c);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor.toARGB32() ==
                                              c.toARGB32()
                                          ? c
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: CircleAvatar(
                                      backgroundColor: c,
                                      child:
                                          selectedColor.toARGB32() ==
                                              c.toARGB32()
                                          ? const Icon(
                                              Icons.check,
                                              size: 20,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 25),
                          Text(
                            "Ícono",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                ),
                            itemCount: _iconList.length,
                            itemBuilder: (context, idx) {
                              final iconData = _iconList[idx];
                              return GestureDetector(
                                onTap: () {
                                  SystemSound.play(SystemSoundType.click);
                                  HapticFeedback.selectionClick();
                                  setDS(() => selectedIcon = iconData);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: selectedIcon == iconData
                                        ? selectedColor.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selectedIcon == iconData
                                          ? selectedColor
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: selectedIcon == iconData
                                        ? selectedColor
                                        : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.end,
                  actions: [
                    TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        String? rStr = selectedReminder != null
                            ? "${selectedReminder!.hour}:${selectedReminder!.minute.toString().padLeft(2, '0')}"
                            : null;
                        provider.addOrUpdateHabit(
                          _habitController.text,
                          selectedColor,
                          selectedIcon.codePoint,
                          rStr,
                          index: index,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        isEdit ? "Guardar" : "Añadir",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startTimerModal(
    Habit habit,
    int initialSeconds,
    HabitProvider provider,
  ) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int timeLeft = initialSeconds;
    Timer? focusTimer;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void startTimer() {
              focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (timeLeft > 0) {
                  setModalState(() => timeLeft--);
                } else {
                  timer.cancel();
                  SystemSound.play(SystemSoundType.alert);
                  HapticFeedback.vibrate();
                  Navigator.pop(context);
                  if (!habit.isCompleted) {
                    provider.toggleHabitCompletion(habit, context);
                  }
                }
              });
            }

            if (focusTimer == null) {
              startTimer();
            }
            String formatTime(int seconds) {
              int min = seconds ~/ 60;
              int sec = seconds % 60;
              return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
            }

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconData(
                        habit.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 50,
                      color: habit.dynamicColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Modo Focus",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      formatTime(timeLeft),
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFEF4444,
                        ).withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text(
                        "Rendirse",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: () {
                        focusTimer?.cancel();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => focusTimer?.cancel());
  }

  void _showTimerSetupModal(Habit habit, HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "¿Cuánto tiempo tomará?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  habit.title,
                  style: TextStyle(
                    color: habit.dynamicColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [10, 15, 30, 60]
                      .map(
                        (mins) => GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _startTimerModal(habit, mins * 60, provider);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: habit.dynamicColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$mins",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "min",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (!provider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                size: 80,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              const Text(
                "App Bloqueada",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.authenticate,
                child: const Text("Desbloquear"),
              ),
            ],
          ),
        ),
      );
    }

    int completed = provider.myHabits.where((h) => h.isCompleted).length;
    double progress = provider.myHabits.isEmpty
        ? 0.0
        : completed / provider.myHabits.length;

    List<Habit> displayedHabits = provider.myHabits;
    if (provider.currentFilter == "Pendientes") {
      displayedHabits = provider.myHabits.where((h) => !h.isCompleted).toList();
    } else if (provider.currentFilter == "Completadas") {
      displayedHabits = provider.myHabits.where((h) => h.isCompleted).toList();
    }

    String statusMessage = "¡A por todas hoy!";
    if (provider.myHabits.isNotEmpty) {
      if (progress == 0) {
        statusMessage = "¡Empieza tu primer hábito!";
      } else if (progress < 0.5) {
        statusMessage = "¡Buen comienzo!";
      } else if (progress < 1.0) {
        statusMessage = "¡Casi lo logras!";
      } else {
        statusMessage = "¡Día perfecto, felicidades!";
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final bool isPerfectDay = progress == 1.0 && provider.myHabits.isNotEmpty;
    final Color barColor = isPerfectDay
        ? Colors.amber
        : const Color(0xFF10B981);
    final Color barBgColor = isPerfectDay
        ? Colors.amber.withValues(alpha: 0.1)
        : const Color(0xFF10B981).withValues(alpha: 0.15);

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              SystemSound.play(SystemSoundType.click);
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Nvl ${provider.playerLevel}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "VitalHabit",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.bar_chart_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => _showStatsModal(provider),
              tooltip: "Estadísticas",
            ),
            IconButton(
              icon: Icon(
                Icons.palette_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => _showThemePicker(provider),
              tooltip: "Temas",
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_getGreeting()}, Nardo",
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: barColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getDate(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: barBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$completed / ${provider.myHabits.length}",
                          style: TextStyle(
                            color: isPerfectDay
                                ? Colors.amber[700]
                                : const Color(0xFF059669),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: isDark && progress > 0
                              ? BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  color: barColor,
                                  minHeight: 12,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        child: Text("${(progress * 100).toInt()}%"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (provider.myHabits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Todas", "Pendientes", "Completadas"].map((
                      filterName,
                    ) {
                      final bool isSelected =
                          provider.currentFilter == filterName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            filterName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          selectedColor: const Color(0xFF2563EB),
                          showCheckmark: false,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (bool selected) {
                            SystemSound.play(SystemSoundType.click);
                            HapticFeedback.selectionClick();
                            context.read<HabitProvider>().setFilter(filterName);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            Expanded(
              child: displayedHabits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Icon(
                              provider.myHabits.isEmpty
                                  ? Icons.rocket_launch_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 80,
                              color: subTextColor.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.myHabits.isEmpty
                                ? "Tu día está en blanco"
                                : "No hay tareas aquí",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.myHabits.isEmpty
                                ? "Toca el botón + para forjar un nuevo hábito"
                                : "Cambia de filtro para ver más",
                            style: TextStyle(color: subTextColor, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : provider.currentFilter == "Todas"
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: displayedHabits.length,
                      onReorder: (oldIdx, newIdx) {
                        HapticFeedback.heavyImpact();
                        context.read<HabitProvider>().reorderHabits(
                          oldIdx,
                          newIdx,
                        );
                      },
                      itemBuilder: (context, index) => _buildHabitCard(
                        displayedHabits[index],
                        index,
                        isDark,
                        textColor,
                        subTextColor,
                        provider,
                        reorderable: true,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: displayedHabits.length,
                      itemBuilder: (context, index) => _buildHabitCard(
                        displayedHabits[index],
                        provider.myHabits.indexOf(displayedHabits[index]),
                        isDark,
                        textColor,
                        subTextColor,
                        provider,
                        reorderable: false,
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            SystemSound.play(SystemSoundType.click);
            HapticFeedback.selectionClick();
            _showHabitDialog();
          },
          backgroundColor: const Color(0xFF2563EB),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHabitCard(
    Habit habit,
    int realIndex,
    bool isDark,
    Color textColor,
    Color subTextColor,
    HabitProvider provider, {
    required bool reorderable,
  }) {
    final itemBgColor = habit.isCompleted
        ? habit.dynamicColor
        : Theme.of(context).cardColor;
    final itemTitleColor = habit.isCompleted ? Colors.white : textColor;
    final itemSubColor = habit.isCompleted ? Colors.white70 : subTextColor;

    return Container(
      key: ValueKey(habit.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: habit.isCompleted
            ? Border.all(
                color: habit.dynamicColor.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: (isDark || habit.isCompleted)
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Dismissible(
          key: Key("dismiss_${habit.id}"),
          direction: DismissDirection.horizontal,
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              _showHabitDialog(index: realIndex);
              return false;
            }
            return true;
          },
          onDismissed: (_) {
            final deletedHabit = provider.myHabits[realIndex];
            provider.deleteHabit(realIndex);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Hábito eliminado",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: "DESHACER",
                  textColor: const Color(0xFF34D399),
                  onPressed: () => context.read<HabitProvider>().insertHabit(
                    realIndex,
                    deletedHabit,
                  ),
                ),
              ),
            );
          },
          background: Container(
            color: const Color(0xFF3B82F6),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          secondaryBackground: Container(
            color: const Color(0xFFEF4444),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: Material(
            color: itemBgColor,
            child: InkWell(
              onTap: () {
                SystemSound.play(SystemSoundType.click);
                HapticFeedback.lightImpact();
                provider.toggleHabitCompletion(habit, context);
              },
              onLongPress: () => _showTimerSetupModal(habit, provider),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: habit.isCompleted
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(
                          habit.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: itemTitleColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: itemTitleColor,
                              decoration: habit.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.white70,
                              decorationThickness: 2,
                            ),
                            child: Text(
                              habit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                habit.streak >= 7
                                    ? "🏆 Super Racha: ${habit.streak} días"
                                    : habit.streak >= 3
                                    ? "🔥 Racha: ${habit.streak} días"
                                    : "Racha: ${habit.streak} días",
                                style: TextStyle(
                                  color: itemSubColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (habit.reminderTime != null &&
                                  !habit.isCompleted) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.notifications_active_rounded,
                                  size: 14,
                                  color: itemSubColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  habit.reminderTime!,
                                  style: TextStyle(
                                    color: itemSubColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: habit.isCompleted
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: OverflowBox(
                                maxWidth: 80,
                                maxHeight: 80,
                                child: Lottie.asset(
                                  'assets/animations/success.json',
                                  repeat: false,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.circle_outlined,
                              size: 35,
                              color: subTextColor.withValues(alpha: 0.5),
                            ),
                    ),
                    if (reorderable) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.drag_indicator_rounded,
                        color: subTextColor.withValues(alpha: 0.3),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
