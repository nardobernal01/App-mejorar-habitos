import 'package:flutter/material.dart';

class Habit {
  String id;
  String title;
  int iconCodePoint;
  int colorValue;
  int streak;
  bool isCompleted;
  DateTime? lastCompletedDate;
  String? reminderTime;

  List<int> activeDays;
  bool isAlarm;
  DateTime? specificDate; // ¡NUEVO! Fecha específica en el calendario

  Habit({
    String? id,
    required this.title,
    required Color color,
    required this.iconCodePoint,
    this.streak = 0,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.reminderTime,
    List<int>? activeDays,
    this.isAlarm = false,
    this.specificDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       colorValue = color.toARGB32(),
       activeDays = activeDays ?? [1, 2, 3, 4, 5, 6, 7];

  Color get dynamicColor => Color(colorValue);

  set dynamicColor(Color color) {
    colorValue = color.toARGB32();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'streak': streak,
      'isCompleted': isCompleted,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'reminderTime': reminderTime,
      'activeDays': activeDays,
      'isAlarm': isAlarm,
      'specificDate': specificDate?.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      color: Color(map['colorValue']),
      iconCodePoint: map['iconCodePoint'],
      streak: map['streak'],
      isCompleted: map['isCompleted'],
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'])
          : null,
      reminderTime: map['reminderTime'],
      activeDays: map['activeDays'] != null
          ? List<int>.from(map['activeDays'])
          : [1, 2, 3, 4, 5, 6, 7],
      isAlarm: map['isAlarm'] ?? false,
      specificDate: map['specificDate'] != null
          ? DateTime.parse(map['specificDate'])
          : null,
    );
  }
}
