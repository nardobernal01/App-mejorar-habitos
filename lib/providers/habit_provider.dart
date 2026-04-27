import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../models/habit_model.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

enum AppThemeMode {
  system,
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

class HabitProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SOLUCIÓN DEFINITIVA: Restauramos tu variable original exacta.
  // Usar 'dynamic' apaga los falsos errores del editor y fuerza la compilación.
  final dynamic _googleSignIn = GoogleSignIn.instance;

  // Timers para notificaciones web simuladas
  final Map<String, Timer> _webReminderTimers = {};
  GlobalKey<NavigatorState>? _navigatorKey;

  void registerNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  List<Habit> _myHabits = [];
  String _userName = "Usuario";
  String _currentFilter = "Todas";
  bool _isPremiumUnlocked = false;
  bool _isAuthenticated = false;
  bool _hasSeenOnboarding = false;
  AppThemeMode _currentTheme = AppThemeMode.system;

  String _userAge = "25";
  String _userGender = "Prefiero no decirlo";
  String? _userPhotoPath;
  bool _useBiometrics = false;
  bool _isUnlocked = false;

  int _playerXP = 0;
  final int _xpPerLevel = 100;
  final Map<DateTime, int> _heatmapDatasets = {};

  String get userAge => _userAge;
  String get userGender => _userGender;
  String? get userPhotoPath => _userPhotoPath;
  bool get useBiometrics => _useBiometrics;
  bool get isUnlocked => _isUnlocked;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  int get playerXP => _playerXP;
  int get xpPerLevel => _xpPerLevel;
  Map<DateTime, int> get heatmapDatasets => _heatmapDatasets;
  List<Habit> get myHabits => _myHabits;
  String get userName => _userName;
  String get currentFilter => _currentFilter;
  bool get isPremiumUnlocked => _isPremiumUnlocked;
  bool get isAuthenticated => _isAuthenticated;
  AppThemeMode get currentTheme => _currentTheme;

  String get playerLevel => ((_playerXP ~/ _xpPerLevel) + 1).toString();
  int get currentLevelXP => _playerXP % _xpPerLevel;
  double get levelProgress => currentLevelXP / _xpPerLevel;

  HabitProvider() {
    _loadLocalData();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userName = user.displayName ?? "Usuario";
        _userPhotoPath = user.photoURL;
        _isAuthenticated = true;
        _isUnlocked = true;
        _loadHabitsFromFirestore();
        notifyListeners();
      } else {
        _isAuthenticated = false;
        _isUnlocked = false;
        _myHabits = [];
        _heatmapDatasets.clear();
        notifyListeners();
      }
    });
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> unlockAppWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Por favor, autentícate para acceder a tus hábitos',
        biometricOnly: false,
      );
      if (didAuthenticate) {
        _isUnlocked = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error de autenticación: $e");
    }
  }

  void updateProfile(
    String name,
    String age,
    String gender,
    String? photoPath,
  ) {
    if (name.isNotEmpty) _userName = name;
    _userAge = age;
    _userGender = gender;
    if (photoPath != null) _userPhotoPath = photoPath;
    _saveLocalData();
    notifyListeners();
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isUnlocked = true;
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error desconocido.";
    }
  }

  Future<String?> registerWithEmail(
    String email,
    String password,
    String name,
    String age,
    String gender,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        _userName = name;
        _userAge = age;
        _userGender = gender;
        _isUnlocked = true;
        await _saveLocalData();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error desconocido.";
    }
  }

  Future<void> authenticate() async {
    try {
      if (kIsWeb) {
        // En Web usamos el flujo oficial y seguro de Firebase sin tocar tu código
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;

        if (user != null) {
          _userName = user.displayName ?? "Usuario";
          _userPhotoPath = user.photoURL;
          _isAuthenticated = true;
          _isUnlocked = true;
          await _saveLocalData();
          await _loadHabitsFromFirestore();
          notifyListeners();
        }
      } else {
        await _googleSignIn.signOut();

        dynamic googleUser;
        try {
          googleUser = await _googleSignIn.signIn();
        } catch (_) {
          // Respaldo de seguridad
          googleUser = await _googleSignIn.authenticate();
        }

        if (googleUser == null) return;

        dynamic authResult;
        try {
          authResult = await googleUser.authentication;
        } catch (_) {
          authResult = googleUser.authentication;
        }

        final credential = GoogleAuthProvider.credential(
          idToken: authResult?.idToken?.toString(),
          accessToken: authResult?.accessToken?.toString(),
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          _userName = user.displayName ?? "Usuario";
          _userPhotoPath = user.photoURL;
          _isAuthenticated = true;
          _isUnlocked = true;
          await _saveLocalData();
          await _loadHabitsFromFirestore();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error en Autenticación: $e");
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
    _isAuthenticated = false;
    _isUnlocked = false;
    _myHabits = [];
    _heatmapDatasets.clear();
    notifyListeners();
  }

  Future<void> _loadHabitsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .get();

      _myHabits = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Habit(
                id: doc.id,
                title: data['title'] ?? 'Sin título',
                // ignore: deprecated_member_use
                color: Color(data['colorValue'] ?? 0xFF10B981),
                iconCodePoint: data['iconCodePoint'] ?? Icons.star.codePoint,
                reminderTime: data['reminderTime'],
                activeDays: List<int>.from(
                  data['activeDays'] ?? [1, 2, 3, 4, 5, 6, 7],
                ),
                isAlarm: data['isAlarm'] ?? false,
                specificDate: data['specificDate'] != null
                    ? DateTime.parse(data['specificDate'])
                    : null,
              )
              ..isCompleted = data['isCompleted'] ?? false
              ..streak = data['streak'] ?? 0;
          })
          .toList()
          .reversed
          .toList();

      await _processDailyResets();
      await _loadHeatmapData();

      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando desde la nube: $e");
    }
  }

  Future<void> _processDailyResets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastDateStr = prefs.getString('lastOpenDate');
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (lastDateStr != null) {
      final DateTime lastOpen = DateTime.parse(lastDateStr);
      final int difference = today.difference(lastOpen).inDays;

      if (difference > 0) {
        bool needsCloudUpdate = false;
        for (var habit in _myHabits) {
          if (difference > 1 || (difference == 1 && !habit.isCompleted)) {
            if (habit.streak > 0) {
              habit.streak = 0;
              needsCloudUpdate = true;
            }
          }
          if (habit.isCompleted) {
            habit.isCompleted = false;
            needsCloudUpdate = true;
          }
          if (needsCloudUpdate) {
            _saveHabitToFirestore(habit);
          }
        }
      }
    }
    await prefs.setString('lastOpenDate', today.toIso8601String());
  }

  Future<void> _loadHeatmapData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completion_history')
          .get();
      _heatmapDatasets.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] != null && data['count'] != null) {
          final date = (data['date'] as Timestamp).toDate();
          final cleanDate = DateTime(date.year, date.month, date.day);
          _heatmapDatasets[cleanDate] = data['count'] as int;
        }
      }
    } catch (e) {
      debugPrint("Error cargando heatmap: $e");
    }
  }

  Future<void> _saveHabitToFirestore(Habit habit) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habit.id)
        .set({
          'title': habit.title,
          // ignore: deprecated_member_use
          'colorValue': habit.dynamicColor.value,
          'iconCodePoint': habit.iconCodePoint,
          'reminderTime': habit.reminderTime,
          'activeDays': habit.activeDays,
          'isAlarm': habit.isAlarm,
          'specificDate': habit.specificDate?.toIso8601String(),
          'isCompleted': habit.isCompleted,
          'streak': habit.streak,
        }, SetOptions(merge: true));
  }

  void addOrUpdateHabit(
    String title,
    Color colorParam,
    int iconCode,
    String? time, {
    int? index,
    List<int>? activeDays,
    bool isAlarm = false,
    DateTime? specificDate,
  }) {
    if (title.isEmpty) return;
    final String currentId = index != null
        ? _myHabits[index].id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final newHabit = Habit(
      id: currentId,
      title: title,
      color: colorParam,
      iconCodePoint: iconCode,
      reminderTime: time,
      activeDays: activeDays ?? [1, 2, 3, 4, 5, 6, 7],
      isAlarm: isAlarm,
      specificDate: specificDate,
    );

    if (index != null) {
      newHabit.streak = _myHabits[index].streak;
      newHabit.isCompleted = _myHabits[index].isCompleted;
      _myHabits[index] = newHabit;
    } else {
      _myHabits.insert(0, newHabit);
    }
    _saveHabitToFirestore(newHabit);

    if (!kIsWeb && newHabit.isAlarm && newHabit.reminderTime != null) {
      try {
        final parts = newHabit.reminderTime!.split(':');
        if (parts.length == 2) {
          final now = DateTime.now();
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
          NotificationService.scheduleNotification(
            id: newHabit.id.hashCode,
            title: '¡Es hora de tu hábito!',
            body: newHabit.title,
            scheduledTime: scheduledTime,
          );
        }
      } catch (e) {
        debugPrint("Error programando alarma: $e");
      }
    }

    // Timer web: dispara la notificación simulada exactamente a la hora puesta
    if (kIsWeb && newHabit.reminderTime != null) {
      _scheduleWebReminder(newHabit);
    }
    notifyListeners();
  }

  void toggleHabitCompletion(Habit habit, BuildContext context) async {
    habit.isCompleted = !habit.isCompleted;
    if (habit.isCompleted) {
      habit.streak++;
      _playerXP += 15;

      final Color accentColor = Theme.of(context).colorScheme.primary;
      const Color snackFg = Colors.white;

      if (kIsWeb) {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (ctx) {
            Future.delayed(const Duration(seconds: 3), () {
              if (ctx.mounted) Navigator.of(ctx).maybePop();
            });
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: snackFg,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Hábito completado! +15 XP',
                                  style: TextStyle(
                                    color: snackFg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    color: snackFg.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      } else {
        // En móvil: SnackBar nativo normal
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star_rounded, color: snackFg, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Hábito completado! +15 XP',
                        style: TextStyle(
                          color: snackFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        habit.title,
                        style: TextStyle(
                          color: snackFg.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 6,
          ),
        );
      }
    } else if (habit.streak > 0) {
      habit.streak--;
      _playerXP = (_playerXP - 15).clamp(0, 999999);
    }

    _saveHabitToFirestore(habit);
    _saveLocalData();
    notifyListeners();
  }

  /// Programa un Timer que disparará la notificación web simulada
  /// exactamente cuando llegue la hora configurada en el hábito.
  void _scheduleWebReminder(Habit habit) {
    // Cancelar timer previo si ya existía para este hábito
    _webReminderTimers[habit.id]?.cancel();

    try {
      final parts = habit.reminderTime!.split(':');
      if (parts.length != 2) return;

      final now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // Si ya pasó la hora hoy, programar para mañana
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final delay = scheduledTime.difference(now);

      _webReminderTimers[habit.id] = Timer(delay, () {
        // Buscar el contexto del navigatorKey global — usamos el último contexto
        // disponible a través del navigatorKey registrado en el provider.
        if (_navigatorKey?.currentContext != null) {
          _showWebReminderSimulation(_navigatorKey!.currentContext!, habit);
        }
      });

      debugPrint(
        "⏰ Web reminder programado para '${habit.title}' en ${delay.inMinutes}m ${delay.inSeconds % 60}s",
      );
    } catch (e) {
      debugPrint("Error programando timer web: $e");
    }
  }

  /// Muestra una notificación simulada estilo móvil en la web,
  /// adaptada al tema actual (colores del ColorScheme activo).
  void _showWebReminderSimulation(BuildContext context, Habit habit) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = isDark
        ? colorScheme.surface.withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.97);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subColor = isDark ? Colors.white60 : Colors.black54;
    final Color accentColor = colorScheme.primary;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header tipo notificación móvil
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: accentColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bloom Your Day',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            habit.reminderTime!,
                            style: TextStyle(color: subColor, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Contenido de la notificación
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconData(
                                habit.iconCodePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Es hora de tu hábito!',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Botón de acción
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Auto-cerrar después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
  }

  void deleteHabit(int index) {
    final habitId = _myHabits[index].id;
    _myHabits.removeAt(index);
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .delete();
    }
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremiumUnlocked = prefs.getBool('isPremium') ?? false;
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    _userAge = prefs.getString('userAge') ?? "25";
    _userGender = prefs.getString('userGender') ?? "Prefiero no decirlo";
    _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    _playerXP = prefs.getInt('playerXP') ?? 0;
    int themeIndex = prefs.getInt('themeIndex') ?? 0;
    if (themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
      _currentTheme = AppThemeMode.values[themeIndex];
    }
    if (kIsWeb) {
      _isPremiumUnlocked = true;
    } else {
      _isPremiumUnlocked = prefs.getBool('isPremium') ?? false;
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', _isPremiumUnlocked);
    await prefs.setString('userAge', _userAge);
    await prefs.setString('userGender', _userGender);
    await prefs.setBool('useBiometrics', _useBiometrics);
    await prefs.setInt('playerXP', _playerXP);
    await prefs.setInt('themeIndex', _currentTheme.index);
  }

  void unlockPremium() {
    _isPremiumUnlocked = true;
    _saveLocalData();
    notifyListeners();
  }

  void toggleBiometrics() {
    _useBiometrics = !_useBiometrics;
    _saveLocalData();
    notifyListeners();
  }

  void setTheme(AppThemeMode theme) {
    _currentTheme = theme;
    _saveLocalData();
    notifyListeners();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }
}
