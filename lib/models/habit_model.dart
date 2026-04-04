import 'package:flutter/material.dart';

class Habit {
  final String title;
  int streak;
  bool isCompleted;

  Habit({required this.title, this.streak = 0, this.isCompleted = false});

  // Convierte el Hábito a un formato que el celular entienda (Map)
  Map<String, dynamic> toMap() => {
    'title': title,
    'streak': streak,
    'isCompleted': isCompleted,
  };

  // Crea un Hábito desde los datos guardados
  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    title: map['title'],
    streak: map['streak'],
    isCompleted: map['isCompleted'],
  );

  Color get dynamicColor {
    if (isCompleted) return const Color(0xFF10B981);
    if (streak > 10) return const Color(0xFF1E40AF);
    return const Color(0xFF2563EB);
  }
}
