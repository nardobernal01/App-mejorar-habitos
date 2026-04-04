import 'package:flutter/material.dart';

class Habit {
  final String id; // El ID que faltaba
  String title;
  bool isCompleted;
  int streak;
  Color dynamicColor;
  DateTime? lastCompletedDate;

  Habit({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.streak = 0,
    Color? color,
    this.lastCompletedDate,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       dynamicColor = color ?? const Color(0xFF10B981);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'streak': streak,
      'dynamicColor': dynamicColor.toARGB32(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      streak: map['streak'] ?? 0,
      color: Color(map['dynamicColor']),
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'])
          : null,
    );
  }
}
