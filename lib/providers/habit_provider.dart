import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../models/habit_model.dart';
import '../services/notification_service.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Habit> _myHabits = [];
  String _userName = "Usuario";
  String _currentFilter = "Todas";
  bool _isPremiumUnlocked = false;
  bool _isAuthenticated = false;
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
  int get playerXP => _playerXP;
  int get xpPerLevel => _xpPerLevel;
  Map<DateTime, int> get heatmapDatasets => _heatmapDatasets;
  List<Habit> get myHabits => _myHabits;
  String get userName => _userName;
  String get currentFilter => _currentFilter;
  bool get isPremiumUnlocked => _isPremiumUnlocked;
  bool get isAuthenticated => _isAuthenticated;
  AppThemeMode get currentTheme => _currentTheme;

  String get playerLevel =>
      (_myHabits.fold(0, (int total, h) => total + h.streak) ~/ 10 + 1)
          .toString();

  HabitProvider() {
    _loadLocalData();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userName = user.displayName ?? "Usuario";
        _userPhotoPath = user.photoURL;
        _isAuthenticated = true;
        _loadHabitsFromFirestore();
        notifyListeners();
      } else {
        _isAuthenticated = false;
        _isUnlocked = false;
        _myHabits = [];
        notifyListeners();
      }
    });
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
    if (name.isNotEmpty) {
      _userName = name;
    }
    _userAge = age;
    _userGender = gender;
    if (photoPath != null) {
      _userPhotoPath = photoPath;
    }
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
      await _googleSignIn.initialize();
      await _googleSignIn.signOut();

      // --- CORRECCIÓN EXACTA APLICADA AQUÍ ---
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      // ---------------------------------------

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        _userName = user.displayName ?? "Usuario";
        _userPhotoPath = user.photoURL;
        _isAuthenticated = true;
        _isUnlocked = true;
        await _saveLocalData();
        await _loadHabitsFromFirestore();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error en Google Sign-In: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _isAuthenticated = false;
    _isUnlocked = false;
    _myHabits = [];
    notifyListeners();
  }

  Future<void> _loadHabitsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .get();
      _myHabits = snapshot.docs.map((doc) {
        final data = doc.data();
        return Habit(
            id: doc.id,
            title: data['title'] ?? 'Sin título',
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
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando desde la nube: $e");
    }
  }

  Future<void> _saveHabitToFirestore(Habit habit) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habit.id)
        .set({
          'title': habit.title,
          'colorValue': habit.dynamicColor.toARGB32(),
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
    if (title.isEmpty) {
      return;
    }
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
      _myHabits.add(newHabit);
    }
    _saveHabitToFirestore(newHabit);
    // ... todo el código anterior de addOrUpdateHabit ...
    _saveHabitToFirestore(newHabit);

    // --- NUEVA LÓGICA DE ALARMAS CONECTADA A TU SERVICIO ---
    if (newHabit.isAlarm && newHabit.reminderTime != null) {
      try {
        // Tu reminderTime probablemente viene como "14:30" (String), lo separamos:
        final parts = newHabit.reminderTime!.split(':');
        if (parts.length == 2) {
          final now = DateTime.now();
          // Creamos la fecha exacta de hoy a esa hora
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          // ¡Llamamos a tu función con su nombre y parámetros reales!
          NotificationService.scheduleNotification(
            id: newHabit
                .id
                .hashCode, // Generamos un ID único usando el ID del hábito
            title: '¡Es hora de tu hábito!',
            body: newHabit.title,
            scheduledTime: scheduledTime,
          );
        }
      } catch (e) {
        debugPrint("Error programando alarma: $e");
      }
    }
    // --------------------------------------------------------

    notifyListeners();
  }

  void toggleHabitCompletion(Habit habit, BuildContext context) async {
    habit.isCompleted = !habit.isCompleted;
    if (habit.isCompleted) {
      habit.streak++;
      _playerXP += 15;
    } else if (habit.streak > 0) {
      habit.streak--;
      _playerXP = (_playerXP - 15).clamp(0, 99999);
    }
    _saveHabitToFirestore(habit);
    _saveLocalData();

    final user = _auth.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month}-${today.day}";
      final historyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completion_history')
          .doc(dateKey);

      try {
        if (habit.isCompleted) {
          await historyRef.set({
            'date': Timestamp.fromDate(
              DateTime(today.year, today.month, today.day),
            ),
            'count': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } else {
          await historyRef.set({
            'count': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Error guardando en historial: $e");
      }
    }
    notifyListeners();
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
    _userAge = prefs.getString('userAge') ?? "25";
    _userGender = prefs.getString('userGender') ?? "Prefiero no decirlo";
    _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    _playerXP = prefs.getInt('playerXP') ?? 0;
    int themeIndex = prefs.getInt('themeIndex') ?? 0;

    if (themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
      _currentTheme = AppThemeMode.values[themeIndex];
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
