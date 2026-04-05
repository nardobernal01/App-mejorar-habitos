import 'package:flutter/material.dart';

class Habit {
  final String id;
  String title;
  Color dynamicColor;
  int iconCodePoint;
  bool isCompleted;
  int streak;
  DateTime? lastCompletedDate;
  String? reminderTime;

  Habit({
    String? id,
    required this.title,
    required Color color,
    required this.iconCodePoint,
    this.isCompleted = false,
    this.streak = 0,
    this.lastCompletedDate,
    this.reminderTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       dynamicColor = color;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // CORRECCIÓN PREMIUM: Usamos el nuevo estándar de Flutter en lugar de .value
      'color': dynamicColor.toARGB32(),
      'iconCodePoint': iconCodePoint,
      'isCompleted': isCompleted,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'reminderTime': reminderTime,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String?,
      title: map['title'] ?? '',
      color: Color(map['color'] ?? 0xFF10B981),
      iconCodePoint: map['iconCodePoint'] ?? Icons.star.codePoint,
      isCompleted: map['isCompleted'] ?? false,
      streak: map['streak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'])
          : null,
      reminderTime: map['reminderTime'],
    );
  }
}
