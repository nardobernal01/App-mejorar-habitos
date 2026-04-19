import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit_model.dart';

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
  int _playerXP = 0;
  final int _xpPerLevel = 100;
  final Map<DateTime, int> _heatmapDatasets = {};

  String get userAge => _userAge;
  String get userGender => _userGender;
  String? get userPhotoPath => _userPhotoPath;
  bool get useBiometrics => _useBiometrics;
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
        _myHabits = [];
        notifyListeners();
      }
    });
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
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No se encontró ningún usuario con ese correo.";
      }
      if (e.code == 'wrong-password') {
        return "Contraseña incorrecta.";
      }
      if (e.code == 'invalid-email') {
        return "El formato del correo es inválido.";
      }
      return "Error al iniciar sesión: ${e.message}";
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
        await _saveLocalData();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Este correo ya está registrado.";
      }
      if (e.code == 'weak-password') {
        return "La contraseña debe tener al menos 6 caracteres.";
      }
      return "Error al crear cuenta: ${e.message}";
    } catch (e) {
      return "Error desconocido.";
    }
  }

  Future<void> authenticate() async {
    try {
      await _googleSignIn.initialize();
      await _googleSignIn.signOut();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
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
    try {
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
          });
    } catch (e) {
      debugPrint("Error guardando en la nube: $e");
    }
  }

  Future<void> _deleteHabitFromFirestore(String habitId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      debugPrint("Error borrando en la nube: $e");
    }
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
    notifyListeners();
  }

  // =========================================================
  // 🟢 NUEVO MOTOR DE COMPLETADO: Guarda datos para el Heatmap
  // =========================================================
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

    // 🟢 Lógica del historial en la nube
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
    _deleteHabitFromFirestore(habitId);
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
