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
    }
  }

  void _addNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nuevo Hábito"),
        content: TextField(
          controller: _habitController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Ej. Tarea de Programación",
            border: OutlineInputBorder(),
          ),
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
                  myHabits.add(Habit(title: _habitController.text));
                  _habitController.clear();
                });
                _saveHabits();
                Navigator.pop(context);
              }
            },
            child: const Text("Añadir"),
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
      body: myHabits.isEmpty
          ? const Center(child: Text("Añade un hábito para comenzar"))
          : ListView.builder(
              itemCount: myHabits.length,
              itemBuilder: (context, index) {
                final habit = myHabits[index];

                // 1. EL CONTENEDOR PADRE: Maneja el margen y la sombra estática
                return Container(
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
                  // 2. EL MOLDE DE GALLETAS: Corta todo lo que esté adentro a la misma curva
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Dismissible(
                      // Cambié UniqueKey por el nombre del hábito para mayor estabilidad
                      key: Key(habit.title),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          myHabits.removeAt(index);
                        });
                        _saveHabits();
                      },
                      // 3. EL FONDO ROJO: Ya no necesita curvas, el ClipRRect lo corta
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 25),
                        color: Colors.redAccent,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      // 4. LA TARJETA VERDE: Tampoco necesita curvas ni sombras propias
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        color: habit.dynamicColor,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          title: Text(
                            habit.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            "Racha: ${habit.streak} días",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: habit.isCompleted
                              ? Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: OverflowBox(
                                    maxWidth: 75,
                                    maxHeight: 75,
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
                                  size: 30,
                                ),
                          onTap: () {
                            setState(() {
                              habit.isCompleted = !habit.isCompleted;
                              if (habit.isCompleted) {
                                habit.streak++;
                              } else {
                                habit.streak--;
                              }
                            });
                            _saveHabits();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewHabit,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
