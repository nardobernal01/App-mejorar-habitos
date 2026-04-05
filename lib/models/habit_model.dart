import 'package:flutter/material.dart';

class Habit {
  final String id;
  String title;
  bool isCompleted;
  int streak;
  Color dynamicColor;
  DateTime? lastCompletedDate;
  int iconCodePoint; // NUEVO: Para guardar el ícono elegido

  Habit({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.streak = 0,
    Color? color,
    this.lastCompletedDate,
    int? iconCodePoint,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       dynamicColor = color ?? const Color(0xFF10B981),
       iconCodePoint =
           iconCodePoint ?? Icons.local_fire_department_rounded.codePoint;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'streak': streak,
      'dynamicColor': dynamicColor.toARGB32(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'iconCodePoint': iconCodePoint,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title'] ?? "Sin título",
      isCompleted: map['isCompleted'] ?? false,
      streak: map['streak'] ?? 0,
      color: Color(map['dynamicColor'] ?? const Color(0xFF10B981).toARGB32()),
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'])
          : null,
      // Sistema de seguridad: Si es un hábito viejo, le pone el fueguito
      iconCodePoint:
          map['iconCodePoint'] ?? Icons.local_fire_department_rounded.codePoint,
    );
  }
}
