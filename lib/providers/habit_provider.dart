import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit_model.dart';

enum AppThemeMode {
  light,
  dark,
  amoled,
  dracula,
  forest,
  teaBronze,
  pastelSky,
  emeraldOcean,
  frostedMint,
  watercolor,
}

class HabitProvider extends ChangeNotifier {
  List<Habit> myHabits = [];
  List<String> unlockedAchievements = [];
  String currentFilter = "Todas";

  int playerLevel = 1;
  int playerXP = 0;
  final int xpPerLevel = 500;

  bool isAuthenticated = false;
  bool useBiometrics = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppThemeMode currentTheme = AppThemeMode.dark;
  bool isPremiumUnlocked = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  HabitProvider() {
    _loadData();
    _initNotifications();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString('appTheme') ?? 'dark';
    currentTheme = AppThemeMode.values.firstWhere(
      (e) => e.toString() == themeStr,
      orElse: () => AppThemeMode.dark,
    );

    playerLevel = prefs.getInt('playerLevel') ?? 1;
    playerXP = prefs.getInt('playerXP') ?? 0;
    useBiometrics = prefs.getBool('useBiometrics') ?? false;
    isPremiumUnlocked = prefs.getBool('isPremiumUnlocked') ?? false;

    unlockedAchievements = prefs.getStringList('my_achievements') ?? [];
    final String? data = prefs.getString('my_habits_list');

    if (data != null) {
      myHabits = (json.decode(data) as List)
          .map((i) => Habit.fromMap(i))
          .toList();
      _checkNewDay();
    }

    await authenticate();
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('appTheme', currentTheme.toString());
    prefs.setInt('playerLevel', playerLevel);
    prefs.setInt('playerXP', playerXP);
    prefs.setBool('useBiometrics', useBiometrics);
    prefs.setBool('isPremiumUnlocked', isPremiumUnlocked);

    final String encodedData = json.encode(
      myHabits.map((h) => h.toMap()).toList(),
    );
    prefs.setString('my_habits_list', encodedData);
    prefs.setStringList('my_achievements', unlockedAchievements);
    notifyListeners();
  }

  // --- MOTOR DE RESPALDO (BACKUP) ---
  String exportBackup() {
    final data = {
      'level': playerLevel,
      'xp': playerXP,
      'theme': currentTheme.name,
      'premium': isPremiumUnlocked,
      'biometrics': useBiometrics,
      'achievements': unlockedAchievements,
      'habits': myHabits.map((h) => h.toMap()).toList(),
    };
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    return base64.encode(bytes);
  }

  bool importBackup(String base64String) {
    try {
      final bytes = base64.decode(base64String);
      final jsonString = utf8.decode(bytes);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      playerLevel = data['level'] ?? 1;
      playerXP = data['xp'] ?? 0;

      final themeName = data['theme'] ?? 'dark';
      currentTheme = AppThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeMode.dark,
      );

      isPremiumUnlocked = data['premium'] ?? false;
      useBiometrics = data['biometrics'] ?? false;

      if (data['achievements'] != null) {
        unlockedAchievements = List<String>.from(data['achievements']);
      }
      if (data['habits'] != null) {
        myHabits = (data['habits'] as List)
            .map((i) => Habit.fromMap(i))
            .toList();
      }

      saveData();
      return true;
    } catch (e) {
      return false;
    }
  }

  void unlockPremium() {
    isPremiumUnlocked = true;
    saveData();
  }

  Future<void> authenticate() async {
    if (!useBiometrics) {
      isAuthenticated = true;
      notifyListeners();
      return;
    }
    try {
      final bool canAuth =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (canAuth) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Ingresa tu huella para acceder a VitalHabit',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      } else {
        isAuthenticated = true;
      }
    } catch (e) {
      isAuthenticated = true;
    }
    notifyListeners();
  }

  void toggleBiometrics(bool value) {
    useBiometrics = value;
    saveData();
  }

  void setTheme(AppThemeMode mode) {
    currentTheme = mode;
    saveData();
  }

  void setFilter(String filter) {
    currentFilter = filter;
    notifyListeners();
  }

  void toggleHabitCompletion(Habit habit, BuildContext context) {
    habit.isCompleted = !habit.isCompleted;
    if (habit.isCompleted) {
      habit.streak++;
      habit.lastCompletedDate = DateTime.now();
      gainXP(50, context);
    } else {
      habit.streak--;
    }
    saveData();
    checkAchievements(context);
  }

  void addOrUpdateHabit(
    String title,
    Color color,
    int iconCode,
    String? reminderStr, {
    int? index,
  }) {
    if (index != null) {
      if (reminderStr == null && myHabits[index].reminderTime != null) {
        cancelHabitReminder(myHabits[index]);
      }
      myHabits[index].title = title;
      myHabits[index].dynamicColor = color;
      myHabits[index].iconCodePoint = iconCode;
      myHabits[index].reminderTime = reminderStr;

      if (reminderStr != null) {
        scheduleHabitReminder(myHabits[index]);
      }
    } else {
      final newHabit = Habit(
        title: title,
        color: color,
        iconCodePoint: iconCode,
        reminderTime: reminderStr,
      );
      myHabits.add(newHabit);

      if (reminderStr != null) {
        scheduleHabitReminder(newHabit);
      }
    }
    saveData();
  }

  void deleteHabit(int index) {
    cancelHabitReminder(myHabits[index]);
    myHabits.removeAt(index);
    saveData();
  }

  void insertHabit(int index, Habit habit) {
    myHabits.insert(index, habit);
    if (habit.reminderTime != null) {
      scheduleHabitReminder(habit);
    }
    saveData();
  }

  void reorderHabits(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }
    final item = myHabits.removeAt(oldIndex);
    myHabits.insert(newIndex, item);
    saveData();
  }

  void gainXP(int amount, BuildContext context) {
    playerXP += amount;
    if (playerXP >= xpPerLevel) {
      playerXP -= xpPerLevel;
      playerLevel++;
      _showLevelUpDialog(context);
    }
  }

  void _showLevelUpDialog(BuildContext context) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_rounded,
              size: 80,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(height: 20),
            const Text(
              "¡SUBISTE DE NIVEL!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Ahora eres Nivel $playerLevel",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("¡Excelente!"),
            ),
          ],
        ),
      ),
    );
  }

  void _checkNewDay() {
    final now = DateTime.now();
    bool changed = false;
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
    if (changed) {
      saveData();
    }
  }

  void checkAchievements(BuildContext context) {
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
      saveData();
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "¡Logro Desbloqueado! $achievementName",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      return;
    }
    final parts = habit.reminderTime!.split(":");
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'habit_reminders',
          'Recordatorios',
          importance: Importance.max,
          priority: Priority.high,
        );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      habit.id.hashCode,
      '¡Es hora de tu hábito! 🔔',
      'Toca hacer: ${habit.title}',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void cancelHabitReminder(Habit habit) async {
    await flutterLocalNotificationsPlugin.cancel(habit.id.hashCode);
  }
}
