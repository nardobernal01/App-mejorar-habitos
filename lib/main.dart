import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'models/habit_model.dart';

void main() => runApp(const VitalHabitApp());

class VitalHabitApp extends StatelessWidget {
  const VitalHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitalHabit',
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const HabitScreen(),
    );
  }
}

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final TextEditingController _habitController = TextEditingController();
  final List<Habit> myHabits = [];

  final List<Color> _palette = [
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      myHabits.map((habit) => habit.toMap()).toList(),
    );
    await prefs.setString('my_habits_list', encodedData);
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? habitsString = prefs.getString('my_habits_list');

    if (habitsString != null) {
      final List<dynamic> decodedData = json.decode(habitsString);
      setState(() {
        myHabits.clear();
        myHabits.addAll(
          decodedData.map((item) => Habit.fromMap(item)).toList(),
        );
      });
      _checkNewDay();
    }
  }

  void _checkNewDay() {
    final now = DateTime.now();
    bool changesMade = false;
    setState(() {
      for (var habit in myHabits) {
        if (habit.lastCompletedDate != null) {
          if (habit.lastCompletedDate!.year != now.year ||
              habit.lastCompletedDate!.month != now.month ||
              habit.lastCompletedDate!.day != now.day) {
            habit.isCompleted = false;
            changesMade = true;
          }
        }
      }
    });
    if (changesMade) {
      _saveHabits();
    }
  }

  void _showHabitDialog({int? index}) {
    bool isEdit = index != null;
    _habitController.text = isEdit ? myHabits[index].title : "";
    Color selectedColor = isEdit ? myHabits[index].dynamicColor : _palette[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(isEdit ? "Editar Hábito" : "Nuevo Hábito"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _habitController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Ej. Programar",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _palette.map((color) {
                    bool isSelected =
                        selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: isSelected ? 18 : 12,
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_habitController.text.isNotEmpty) {
                    setState(() {
                      if (isEdit) {
                        myHabits[index].title = _habitController.text;
                        myHabits[index].dynamicColor = selectedColor;
                      } else {
                        myHabits.add(
                          Habit(
                            title: _habitController.text,
                            color: selectedColor,
                          ),
                        );
                      }
                    });
                    _saveHabits();
                    Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? "Guardar" : "Añadir"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard() {
    int total = myHabits.length;
    int completed = myHabits.where((h) => h.isCompleted).length;
    double progress = total == 0 ? 0.0 : completed / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progreso de hoy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "$completed / $total",
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "VitalHabit",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildDashboard(),
          Expanded(
            child: myHabits.isEmpty
                ? const Center(child: Text("Añade un hábito para comenzar"))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: myHabits.length,
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }
                        final item = myHabits.removeAt(oldIndex);
                        myHabits.insert(newIndex, item);
                      });
                      _saveHabits();
                    },
                    itemBuilder: (context, index) {
                      final habit = myHabits[index];

                      return Container(
                        key: ValueKey(habit.id),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
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
                            onDismissed: (dir) {
                              if (dir == DismissDirection.endToStart) {
                                setState(() {
                                  myHabits.removeAt(index);
                                });
                                _saveHabits();
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 25),
                              color: Colors.blueAccent,
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 25),
                              color: Colors.redAccent,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: Material(
                              color: habit.dynamicColor,
                              child: InkWell(
                                onTap: () {
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
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              habit.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (habit.streak >= 7)
                                              Text(
                                                "🏆 Racha: ${habit.streak} días",
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else if (habit.streak >= 3)
                                              Text(
                                                "🔥 Racha: ${habit.streak} días",
                                                style: const TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else
                                              Text(
                                                "Racha: ${habit.streak} días",
                                                style: const TextStyle(
                                                  color: Colors.white70,
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
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
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
                                            : const Icon(
                                                Icons.circle_outlined,
                                                color: Colors.white,
                                                size: 35,
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
        onPressed: () => _showHabitDialog(),
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
