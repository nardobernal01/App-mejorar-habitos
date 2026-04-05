import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models/habit_model.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const VitalHabitApp());
}

class VitalHabitApp extends StatelessWidget {
  const VitalHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (BuildContext context, ThemeMode currentMode, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VitalHabit',
          themeMode: currentMode,
          theme: ThemeData(
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
          ),
          darkTheme: ThemeData(
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
          ),
          home: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: const HabitScreen(),
          ),
        );
      },
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
  final List<Habit> myHabits = [];
  List<String> unlockedAchievements = [];
  final int totalTrophies = 6;

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
    _loadHabits();
    _loadTheme();
    _initNotifications();

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

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _scheduleDailyReminder();
  }

  Future<void> _scheduleDailyReminder() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder',
          'Recordatorio Diario',
          channelDescription: 'Te avisa si olvidaste tus hábitos',
          importance: Importance.max,
          priority: Priority.high,
        );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '¡No rompas tu racha! 🔥',
      'Es hora de revisar tus hábitos de hoy. Entra y completa tu día.',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeNotifier.value == ThemeMode.dark) {
      themeNotifier.value = ThemeMode.light;
      prefs.setBool('isDarkTheme', false);
    } else {
      themeNotifier.value = ThemeMode.dark;
      prefs.setBool('isDarkTheme', true);
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      myHabits.map((h) => h.toMap()).toList(),
    );
    await prefs.setString('my_habits_list', encodedData);
    await prefs.setStringList('my_achievements', unlockedAchievements);
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('my_habits_list');
    unlockedAchievements = prefs.getStringList('my_achievements') ?? [];
    if (data != null) {
      setState(() {
        myHabits.clear();
        myHabits.addAll(
          (json.decode(data) as List).map((i) => Habit.fromMap(i)).toList(),
        );
      });
      _checkNewDay();
    }
  }

  void _checkNewDay() {
    final now = DateTime.now();
    bool changed = false;
    setState(() {
      for (var habit in myHabits) {
        if (habit.lastCompletedDate != null) {
          final lastDate = habit.lastCompletedDate!;
          final today = DateTime(now.year, now.month, now.day);
          final lastCompletedDay = DateTime(
            lastDate.year,
            lastDate.month,
            lastDate.day,
          );
          if (today.difference(lastCompletedDay).inDays > 0) {
            habit.isCompleted = false;
            changed = true;
            if (today.difference(lastCompletedDay).inDays > 1) {
              habit.streak = 0;
            }
          }
        }
      }
    });
    if (changed) {
      _saveHabits();
    }
  }

  void _checkAchievements() {
    bool newlyUnlocked = false;
    String achievementName = "";

    int completedToday = myHabits.where((h) => h.isCompleted).length;
    int maxStreak = myHabits.isEmpty
        ? 0
        : myHabits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final hour = DateTime.now().hour;

    if (completedToday >= 1 && !unlockedAchievements.contains("primer_paso")) {
      unlockedAchievements.add("primer_paso");
      achievementName = "Primera Sangre 🩸";
      newlyUnlocked = true;
    }
    if (maxStreak >= 3 && !unlockedAchievements.contains("racha_3")) {
      unlockedAchievements.add("racha_3");
      achievementName = "Disciplinado 🔥";
      newlyUnlocked = true;
    }
    if (maxStreak >= 7 && !unlockedAchievements.contains("racha_7")) {
      unlockedAchievements.add("racha_7");
      achievementName = "Imparable 🏆";
      newlyUnlocked = true;
    }
    if (maxStreak >= 14 && !unlockedAchievements.contains("racha_14")) {
      unlockedAchievements.add("racha_14");
      achievementName = "Titán del Hábito 👑";
      newlyUnlocked = true;
    }
    if (hour < 8 &&
        completedToday >= 1 &&
        !unlockedAchievements.contains("madrugador")) {
      unlockedAchievements.add("madrugador");
      achievementName = "Madrugador ☕";
      newlyUnlocked = true;
    }
    if (myHabits.length >= 3 &&
        completedToday == myHabits.length &&
        !unlockedAchievements.contains("perfeccion")) {
      unlockedAchievements.add("perfeccion");
      achievementName = "Día Perfecto ⭐";
      newlyUnlocked = true;
    }

    if (newlyUnlocked) {
      _saveHabits();
      HapticFeedback.heavyImpact();
      final isDark = themeNotifier.value == ThemeMode.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "¡Logro Desbloqueado!\n$achievementName",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E3A8A)
              : const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAchievementsModal() {
    final isDark = themeNotifier.value == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.8,
              expand: false,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
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
                            "Tus Trofeos",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${unlockedAchievements.length}/$totalTrophies",
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            _buildTrophyRow(
                              "Primera Sangre",
                              "Completa 1 hábito",
                              Icons.water_drop_rounded,
                              unlockedAchievements.contains("primer_paso"),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTrophyRow(
                              "Madrugador",
                              "Completa un hábito antes de las 8 AM",
                              Icons.wb_sunny_rounded,
                              unlockedAchievements.contains("madrugador"),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTrophyRow(
                              "Disciplinado",
                              "Alcanza racha de 3",
                              Icons.local_fire_department_rounded,
                              unlockedAchievements.contains("racha_3"),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTrophyRow(
                              "Imparable",
                              "Alcanza racha de 7",
                              Icons.bolt_rounded,
                              unlockedAchievements.contains("racha_7"),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTrophyRow(
                              "Titán del Hábito",
                              "Alcanza racha de 14",
                              Icons.diamond_rounded,
                              unlockedAchievements.contains("racha_14"),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTrophyRow(
                              "Día Perfecto",
                              "Completa todos (Mín. 3)",
                              Icons.verified_rounded,
                              unlockedAchievements.contains("perfeccion"),
                              isDark,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrophyRow(
    String title,
    String desc,
    IconData icon,
    bool isUnlocked,
    bool isDark,
  ) {
    final lockedBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final lockedIconColor = isDark ? Colors.white38 : Colors.black38;
    final lockedTitleColor = isDark ? Colors.white70 : Colors.black54;
    final lockedDescColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : lockedBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF10B981) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: isUnlocked ? const Color(0xFF10B981) : lockedIconColor,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isUnlocked
                        ? (isDark ? Colors.white : Colors.black87)
                        : lockedTitleColor,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: isUnlocked
                        ? (isDark ? Colors.white70 : Colors.black54)
                        : lockedDescColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          isUnlocked
              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
              : Icon(Icons.lock_rounded, color: lockedIconColor),
        ],
      ),
    );
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

  void _performSave(String title, Color color, IconData icon, {int? index}) {
    FocusScope.of(context).unfocus();
    if (title.trim().isNotEmpty) {
      setState(() {
        if (index != null) {
          myHabits[index].title = title.trim();
          myHabits[index].dynamicColor = color;
          myHabits[index].iconCodePoint = icon.codePoint;
        } else {
          myHabits.add(
            Habit(
              title: title.trim(),
              color: color,
              iconCodePoint: icon.codePoint,
            ),
          );
        }
      });
      _saveHabits();
    }
  }

  // RESTAURADO: Diálogo centrado ágil con efecto resorte y cristal.
  void _showHabitDialog({int? index}) {
    bool isEdit = index != null;
    _habitController.text = isEdit ? myHabits[index].title : "";
    Color selectedColor = isEdit ? myHabits[index].dynamicColor : _palette[0];
    IconData selectedIcon = isEdit
        ? IconData(myHabits[index].iconCodePoint, fontFamily: 'MaterialIcons')
        : _iconList[0];
    final isDark = themeNotifier.value == ThemeMode.dark;

    final List<Map<String, dynamic>> quickActions = [
      {
        "label": "💧 Agua",
        "title": "Tomar 2L de agua",
        "color": _palette[1],
        "icon": _iconList[3],
      },
      {
        "label": "🍎 Comer",
        "title": "Comida saludable",
        "color": _palette[4],
        "icon": _iconList[6],
      },
      {
        "label": "📖 Leer",
        "title": "Leer 15 minutos",
        "color": _palette[3],
        "icon": _iconList[2],
      },
      {
        "label": "🏋️ Ejercicio",
        "title": "Hacer ejercicio",
        "color": _palette[6],
        "icon": _iconList[1],
      },
      {
        "label": "🧹 Ordenar",
        "title": "Limpiar habitación",
        "color": _palette[2],
        "icon": _iconList[7],
      },
      {
        "label": "🧘 Meditar",
        "title": "Meditar 10 min",
        "color": _palette[7],
        "icon": _iconList[4],
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
                  title: Text(
                    isEdit ? "Editar Hábito" : "Nuevo Hábito",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 5),
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
                                          HapticFeedback.mediumImpact();
                                          if (isEdit) {
                                            setDS(() {
                                              _habitController.text =
                                                  action["title"];
                                              selectedColor = action["color"];
                                              selectedIcon = action["icon"];
                                            });
                                          } else {
                                            _performSave(
                                              action["title"],
                                              action["color"],
                                              action["icon"],
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
                          const SizedBox(height: 25),
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
                        _performSave(
                          _habitController.text,
                          selectedColor,
                          selectedIcon,
                          index: index,
                        );
                        if (isEdit) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    int completed = myHabits.where((h) => h.isCompleted).length;
    double progress = myHabits.isEmpty ? 0.0 : completed / myHabits.length;

    String statusMessage = "¡A por todas hoy!";
    if (myHabits.isNotEmpty) {
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

    final isDark = themeNotifier.value == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    // CONSERVADO: Colores para el "Modo Dios" (100% completado)
    final bool isPerfectDay = progress == 1.0 && myHabits.isNotEmpty;
    final Color barColor = isPerfectDay
        ? Colors.amber
        : const Color(0xFF10B981);
    final Color barBgColor = isPerfectDay
        ? Colors.amber.withValues(alpha: 0.1)
        : const Color(0xFF10B981).withValues(alpha: 0.15);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "VitalHabit",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.emoji_events_rounded,
              color: isDark ? Colors.amber : Colors.amber[700],
            ),
            onPressed: _showAchievementsModal,
            tooltip: "Ver Logros",
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: "Cambiar Tema",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                        "$completed / ${myHabits.length}",
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

          Expanded(
            child: myHabits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            size: 80,
                            color: subTextColor.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tu día está en blanco",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Toca el botón + para forjar un nuevo hábito",
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: myHabits.length,
                    onReorder: (oldIdx, newIdx) {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = myHabits.removeAt(oldIdx);
                        myHabits.insert(newIdx, item);
                      });
                      _saveHabits();
                    },
                    itemBuilder: (context, index) {
                      final habit = myHabits[index];
                      final itemBgColor = habit.isCompleted
                          ? habit.dynamicColor
                          : Theme.of(context).cardColor;
                      final itemTitleColor = habit.isCompleted
                          ? Colors.white
                          : textColor;
                      final itemSubColor = habit.isCompleted
                          ? Colors.white70
                          : subTextColor;

                      return Container(
                        key: ValueKey(habit.id),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: habit.isCompleted
                              ? Border.all(
                                  color: habit.dynamicColor.withValues(
                                    alpha: 0.5,
                                  ),
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
                                _showHabitDialog(index: index);
                                return false;
                              }
                              return true;
                            },
                            onDismissed: (_) {
                              final deletedHabit = myHabits[index];
                              setState(() => myHabits.removeAt(index));
                              _saveHabits();
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
                                    onPressed: () {
                                      setState(
                                        () => myHabits.insert(
                                          index,
                                          deletedHabit,
                                        ),
                                      );
                                      _saveHabits();
                                    },
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
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    habit.isCompleted = !habit.isCompleted;
                                    if (habit.isCompleted) {
                                      habit.streak++;
                                      habit.lastCompletedDate = DateTime.now();
                                    } else {
                                      habit.streak--;
                                    }
                                  });
                                  _saveHabits();
                                  _checkAchievements();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: habit.isCompleted
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : (isDark
                                                    ? Colors.white10
                                                    : Colors.black.withValues(
                                                        alpha: 0.05,
                                                      )),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
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
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 5,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
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
                                                color: subTextColor.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.drag_indicator_rounded,
                                        color: subTextColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          _showHabitDialog();
        },
        backgroundColor: const Color(0xFF2563EB),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
