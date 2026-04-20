import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';

// NUEVOS IMPORTS
import 'package:confetti/confetti.dart';
import '../widgets/empty_state_widget.dart';

import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'profile_screen.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});
  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _habitController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  // CONTROLADOR DEL CONFETI
  late ConfettiController _confettiController;

  final List<Color> _palette = [
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFF6366F1),
  ];

  final List<IconData> _iconList = [
    Icons.local_fire_department_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.water_drop_rounded,
    Icons.self_improvement_rounded,
    Icons.monitor_rounded,
    Icons.restaurant_rounded,
    Icons.cleaning_services_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // INICIALIZAR CONFETI
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    // LIMPIAR CONFETI
    _confettiController.dispose();

    _habitController.dispose();
    super.dispose();
  }

  Future<void> _shareStats(HabitProvider provider) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File(
          '${directory.path}/bloom_your_day_stats.png',
        ).create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              '🔥 ¡Dominando mis hábitos en Nivel ${provider.playerLevel} con Bloom Your Day!',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al compartir')));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) {
      return "Buenas madrugadas";
    }
    if (hour < 12) {
      return "Buenos días";
    }
    if (hour < 19) {
      return "Buenas tardes";
    }
    return "Buenas noches";
  }

  String _getDate() {
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final now = DateTime.now();
    return "${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}";
  }

  void _showProPaywall(HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 80,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 20),
              const Text(
                "BLOOM YOUR DAY PRO",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Desbloquea 8 temas premium exclusivos, colores ilimitados y seguridad biométrica avanzada.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  SystemSound.play(SystemSoundType.alert);
                  provider.unlockPremium();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Felicidades! Eres usuario PRO 💎',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                },
                child: const Text(
                  "Desbloquear ahora (\$2.99/m)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Quizá más tarde",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = provider.isPremiumUnlocked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Apariencia",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children:
                      [
                        AppThemeMode.system,
                        AppThemeMode.light,
                        AppThemeMode.dark,
                      ].map((mode) {
                        return ChoiceChip(
                          label: Text(mode.name.toUpperCase()),
                          selected: provider.currentTheme == mode,
                          onSelected: (selected) {
                            SystemSound.play(SystemSoundType.click);
                            HapticFeedback.selectionClick();
                            context.read<HabitProvider>().setTheme(mode);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children:
                      [
                        AppThemeMode.amoled,
                        AppThemeMode.dracula,
                        AppThemeMode.forest,
                        AppThemeMode.teaBronze,
                        AppThemeMode.pastelSky,
                        AppThemeMode.emeraldOcean,
                        AppThemeMode.frostedMint,
                        AppThemeMode.watercolor,
                      ].map((mode) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isPro)
                                const Icon(Icons.lock_rounded, size: 14),
                              if (!isPro) const SizedBox(width: 4),
                              Text(mode.name.toUpperCase()),
                            ],
                          ),
                          selectedColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.3),
                          selected: provider.currentTheme == mode,
                          onSelected: (selected) {
                            SystemSound.play(SystemSoundType.click);
                            HapticFeedback.selectionClick();
                            if (isPro) {
                              context.read<HabitProvider>().setTheme(mode);
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);
                              _showProPaywall(provider);
                            }
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsModal(HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalCompletions = provider.myHabits.fold(
      0,
      (sum, habit) => sum + habit.streak,
    );
    int maxStreak = provider.myHabits.isEmpty
        ? 0
        : provider.myHabits
              .map((h) => h.streak)
              .reduce((a, b) => a > b ? a : b);
    double successRate = provider.myHabits.isEmpty
        ? 0
        : (provider.myHabits.where((h) => h.isCompleted).length /
                  provider.myHabits.length) *
              100;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tu Rendimiento",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFF2563EB),
                      ),
                      onPressed: () => _shareStats(provider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      "Tasa Éxito",
                      "${successRate.toInt()}%",
                      Icons.pie_chart_rounded,
                      const Color(0xFF10B981),
                      isDark,
                    ),
                    _buildStatCard(
                      "Racha",
                      "$maxStreak",
                      Icons.local_fire_department_rounded,
                      const Color(0xFFF59E0B),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      "Completados",
                      "$totalCompletions",
                      Icons.check_circle_rounded,
                      const Color(0xFF3B82F6),
                      isDark,
                    ),
                    _buildStatCard(
                      "Hábitos",
                      "${provider.myHabits.length}",
                      Icons.format_list_bulleted_rounded,
                      const Color(0xFF8B5CF6),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitDialog({int? index}) {
    SystemSound.play(SystemSoundType.click);
    final provider = context.read<HabitProvider>();
    bool isEdit = index != null;

    _habitController.text = isEdit ? provider.myHabits[index].title : "";
    Color selectedColor = isEdit
        ? provider.myHabits[index].dynamicColor
        : _palette[0];
    IconData selectedIcon = isEdit
        ? IconData(
            provider.myHabits[index].iconCodePoint,
            fontFamily: 'MaterialIcons',
          )
        : _iconList[0];

    TimeOfDay? selectedTime;
    DateTime? selectedDate = isEdit
        ? provider.myHabits[index].specificDate
        : null;
    List<int> selectedDays = isEdit
        ? List.from(provider.myHabits[index].activeDays)
        : [1, 2, 3, 4, 5, 6, 7];
    bool triggerAlarm = isEdit ? provider.myHabits[index].isAlarm : false;
    final List<String> dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    if (isEdit && provider.myHabits[index].reminderTime != null) {
      final parts = provider.myHabits[index].reminderTime!.split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: StatefulBuilder(
              builder: (context, setDS) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEdit ? "Editar Hábito" : "Nuevo Hábito",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _habitController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "Ej. Leer 10 páginas, Cumpleaños...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              "Programación",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedTime ?? TimeOfDay.now(),
                                      );
                                      if (time != null) {
                                        setDS(() => selectedTime = time);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selectedTime != null
                                            ? const Color(
                                                0xFF2563EB,
                                              ).withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selectedTime != null
                                              ? const Color(0xFF2563EB)
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 18,
                                            color: selectedTime != null
                                                ? const Color(0xFF2563EB)
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            selectedTime != null
                                                ? selectedTime!.format(context)
                                                : "Hora",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: selectedTime != null
                                                  ? const Color(0xFF2563EB)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            selectedDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        setDS(() => selectedDate = date);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selectedDate != null
                                            ? const Color(
                                                0xFFF59E0B,
                                              ).withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selectedDate != null
                                              ? const Color(0xFFF59E0B)
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 18,
                                            color: selectedDate != null
                                                ? const Color(0xFFF59E0B)
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            selectedDate != null
                                                ? "${selectedDate!.day}/${selectedDate!.month}"
                                                : "Fecha Única",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: selectedDate != null
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            if (selectedDate == null) ...[
                              Text(
                                "Repetir los días",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(7, (index) {
                                  int dayValue = index + 1;
                                  bool isSelected = selectedDays.contains(
                                    dayValue,
                                  );
                                  return FilterChip(
                                    label: Text(dayLabels[index]),
                                    selected: isSelected,
                                    selectedColor: selectedColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    checkmarkColor: selectedColor,
                                    onSelected: (val) {
                                      setDS(() {
                                        if (val) {
                                          selectedDays.add(dayValue);
                                        } else if (selectedDays.length > 1) {
                                          selectedDays.remove(dayValue);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available_rounded,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        "Evento único programado",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setDS(() => selectedDate = null),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (selectedTime != null) ...[
                              const SizedBox(height: 16),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  "Recibir recordatorio",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Sonará incluso en silencio",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                value: triggerAlarm,
                                activeThumbColor: const Color(0xFFEF4444),
                                onChanged: (val) =>
                                    setDS(() => triggerAlarm = val),
                              ),
                            ],

                            const SizedBox(height: 24),
                            Text(
                              "Color",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                  ),
                              itemCount: _palette.length,
                              itemBuilder: (context, idx) {
                                final c = _palette[idx];
                                return GestureDetector(
                                  onTap: () {
                                    SystemSound.play(SystemSoundType.click);
                                    setDS(() => selectedColor = c);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            selectedColor.toARGB32() ==
                                                c.toARGB32()
                                            ? c
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: CircleAvatar(
                                        backgroundColor: c,
                                        child:
                                            selectedColor.toARGB32() ==
                                                c.toARGB32()
                                            ? const Icon(
                                                Icons.check,
                                                size: 20,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Ícono",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                  ),
                              itemCount: _iconList.length,
                              itemBuilder: (context, idx) {
                                final iconData = _iconList[idx];
                                return GestureDetector(
                                  onTap: () {
                                    SystemSound.play(SystemSoundType.click);
                                    setDS(() => selectedIcon = iconData);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: selectedIcon == iconData
                                          ? selectedColor.withValues(
                                              alpha: 0.15,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selectedIcon == iconData
                                            ? selectedColor
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: selectedIcon == iconData
                                          ? selectedColor
                                          : (isDark
                                                ? Colors.white54
                                                : Colors.black54),
                                      size: 28,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          String? rStr = selectedTime != null
                              ? "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                              : null;
                          provider.addOrUpdateHabit(
                            _habitController.text,
                            selectedColor,
                            selectedIcon.codePoint,
                            rStr,
                            index: index,
                            activeDays: selectedDays,
                            isAlarm: triggerAlarm,
                            specificDate: selectedDate,
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEdit ? "Guardar Cambios" : "Añadir a mi Día",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _startTimerModal(
    Habit habit,
    int initialSeconds,
    HabitProvider provider,
  ) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int timeLeft = initialSeconds;
    Timer? focusTimer;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void startTimer() {
              focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (timeLeft > 0) {
                  setModalState(() => timeLeft--);
                } else {
                  timer.cancel();
                  SystemSound.play(SystemSoundType.alert);
                  HapticFeedback.vibrate();
                  Navigator.pop(context);
                  if (!habit.isCompleted) {
                    provider.toggleHabitCompletion(habit, context);
                  }
                }
              });
            }

            if (focusTimer == null) {
              startTimer();
            }
            String formatTime(int seconds) {
              int min = seconds ~/ 60;
              int sec = seconds % 60;
              return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
            }

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconData(
                        habit.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 50,
                      color: habit.dynamicColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Modo Focus",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // ... (código anterior: Icono, Modo Focus, Título) ...
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30), // Espacio antes del reloj
                    // AQUÍ ESTÁ EL RELOJ GIGANTE (Asegúrate de tener esto)
                    Text(
                      formatTime(timeLeft),
                      style: TextStyle(
                        fontSize: 60, // ¡Reloj grande!
                        fontWeight: FontWeight.w900,
                        color: habit.dynamicColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(height: 15), // Espacio antes del aviso
                    // AQUÍ VA NUESTRO NUEVO AVISO DE LA BOMBILLA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Mantén la pantalla encendida",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30), // Espacio antes de los botones
                    // ... (código siguiente: Row con los botones de play/pause) ...
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFEF4444,
                        ).withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text(
                        "Rendirse",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: () {
                        focusTimer?.cancel();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => focusTimer?.cancel());
  }

  void _showTimerSetupModal(Habit habit, HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "¿Cuánto tiempo tomará?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  habit.title,
                  style: TextStyle(
                    color: habit.dynamicColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [10, 15, 30, 60]
                      .map(
                        (mins) => GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _startTimerModal(habit, mins * 60, provider);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: habit.dynamicColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$mins",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "min",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (!provider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                size: 80,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              const Text(
                "App Bloqueada",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.authenticate,
                child: const Text("Desbloquear"),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    List<Habit> displayedHabits = provider.myHabits.where((h) {
      if (h.specificDate != null) {
        return h.specificDate!.year == now.year &&
            h.specificDate!.month == now.month &&
            h.specificDate!.day == now.day;
      }
      return h.activeDays.contains(now.weekday);
    }).toList();

    int completed = displayedHabits.where((h) => h.isCompleted).length;
    double progress = displayedHabits.isEmpty
        ? 0.0
        : completed / displayedHabits.length;

    if (provider.currentFilter == "Pendientes") {
      displayedHabits = displayedHabits.where((h) => !h.isCompleted).toList();
    } else if (provider.currentFilter == "Completadas") {
      displayedHabits = displayedHabits.where((h) => h.isCompleted).toList();
    }

    String statusMessage = "¡A por todas hoy!";

    if (displayedHabits.isNotEmpty) {
      if (progress == 0) {
        statusMessage = "¡Empieza tu primer hábito!";
      } else if (progress < 0.5) {
        statusMessage = "¡Buen comienzo!";
      } else if (progress < 1.0) {
        statusMessage = "¡Casi lo logras!";
      } else {
        statusMessage = "¡Día perfecto, felicidades!";
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final bool isPerfectDay = progress == 1.0 && displayedHabits.isNotEmpty;
    final Color barColor = isPerfectDay
        ? Colors.amber
        : const Color(0xFF10B981);
    final Color barBgColor = isPerfectDay
        ? Colors.amber.withValues(alpha: 0.1)
        : const Color(0xFF10B981).withValues(alpha: 0.15);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Screenshot(
          controller: _screenshotController,
          // AQUÍ EMPIEZA LA MAGIA DEL STACK Y CONFETI
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Nvl ${provider.playerLevel}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Bloom Your Day",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.bar_chart_rounded, color: subTextColor),
                      onPressed: () => _showStatsModal(provider),
                    ),
                    IconButton(
                      icon: Icon(Icons.palette_rounded, color: subTextColor),
                      onPressed: () => _showThemePicker(provider),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "${_getGreeting()}, ${provider.userName}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                statusMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: barColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getDate(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: barBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$completed / ${displayedHabits.length}",
                                  style: TextStyle(
                                    color: isPerfectDay
                                        ? Colors.amber[700]
                                        : const Color(0xFF059669),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: progress,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, _) {
                                        return LinearProgressIndicator(
                                          value: value,
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          color: barColor,
                                          minHeight: 12,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: TextStyle(
                                  color: barColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (provider.myHabits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ["Todas", "Pendientes", "Completadas"]
                                .map((filterName) {
                                  final bool isSelected =
                                      provider.currentFilter == filterName;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(
                                        filterName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.white
                                              : textColor,
                                        ),
                                      ),
                                      selected: isSelected,
                                      backgroundColor: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      selectedColor: const Color(0xFF2563EB),
                                      showCheckmark: false,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      onSelected: (bool selected) {
                                        context.read<HabitProvider>().setFilter(
                                          filterName,
                                        );
                                      },
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    Expanded(
                      // AQUÍ APLICAMOS LA MAGIA DEL EMPTY STATE
                      child: displayedHabits.isEmpty
                          ? const EmptyStateWidget()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: displayedHabits.length,
                              itemBuilder: (context, index) => _buildHabitCard(
                                displayedHabits[index],
                                provider.myHabits.indexOf(
                                  displayedHabits[index],
                                ),
                                isDark,
                                textColor,
                                subTextColor,
                                provider,
                                reorderable: false,
                              ),
                            ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _showHabitDialog(),
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              // EL CAÑÓN DE CONFETI EN LA CIMA DEL STACK
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFF10B981),
                    Colors.blue,
                    Colors.orange,
                    Colors.pink,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(
    Habit habit,
    int realIndex,
    bool isDark,
    Color textColor,
    Color subTextColor,
    HabitProvider provider, {
    required bool reorderable,
  }) {
    final bool isLightColor = habit.dynamicColor.computeLuminance() > 0.5;
    final Color completedTextColor = isLightColor
        ? Colors.black87
        : Colors.white;
    final Color completedSubTextColor = isLightColor
        ? Colors.black54
        : Colors.white70;

    final itemBgColor = habit.isCompleted
        ? habit.dynamicColor
        : Theme.of(context).cardColor;
    final itemTitleColor = habit.isCompleted ? completedTextColor : textColor;
    final itemSubColor = habit.isCompleted
        ? completedSubTextColor
        : subTextColor;

    return Container(
      key: ValueKey(habit.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: habit.isCompleted
            ? Border.all(
                color: habit.dynamicColor.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: (isDark || habit.isCompleted)
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Dismissible(
          key: Key("dismiss_${habit.id}"),
          direction: DismissDirection.horizontal,
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              _showHabitDialog(index: realIndex);
              return false;
            }
            return true;
          },
          onDismissed: (_) {
            // Guardamos una copia temporal antes de borrar
            final deletedHabit = habit;

            // Borramos el hábito de la base de datos
            provider.deleteHabit(realIndex);

            // Mostramos el mensaje para "Deshacer"
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Hábito '${deletedHabit.title}' eliminado"),
                behavior: SnackBarBehavior.floating,
                backgroundColor: isDark ? Colors.grey[800] : Colors.black87,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'DESHACER',
                  textColor: const Color(0xFF10B981), // Verde esmeralda
                  onPressed: () {
                    // Si se arrepiente, lo volvemos a meter a la base de datos
                    provider.addOrUpdateHabit(
                      deletedHabit.title,
                      deletedHabit.dynamicColor,
                      deletedHabit.iconCodePoint,
                      deletedHabit.reminderTime,
                      activeDays: deletedHabit.activeDays,
                      isAlarm: deletedHabit.isAlarm,
                      specificDate: deletedHabit.specificDate,
                    );
                  },
                ),
              ),
            );
          },
          background: Container(
            color: const Color(0xFF3B82F6),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          secondaryBackground: Container(
            color: const Color(0xFFEF4444),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: Material(
            color: itemBgColor,
            child: InkWell(
              onTap: () {
                // CONFETI SOLO AL 100% DE HÁBITOS
                if (!habit.isCompleted) {
                  final now = DateTime.now();
                  final todayHabits = provider.myHabits.where((h) {
                    if (h.specificDate != null) {
                      return h.specificDate!.year == now.year &&
                          h.specificDate!.month == now.month &&
                          h.specificDate!.day == now.day;
                    }
                    return h.activeDays.contains(now.weekday);
                  }).toList();
                  final alreadyCompleted = todayHabits
                      .where((h) => h.isCompleted)
                      .length;
                  if (alreadyCompleted + 1 == todayHabits.length) {
                    _confettiController.play();
                  }
                }
                provider.toggleHabitCompletion(habit, context);
              },
              onLongPress: () => _showTimerSetupModal(habit, provider),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: habit.isCompleted
                            ? (isLightColor
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.2))
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(
                          habit.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: itemTitleColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: itemTitleColor,
                              decoration: habit.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (habit.specificDate == null)
                                Text(
                                  habit.streak >= 3
                                      ? "🔥 Racha: ${habit.streak}"
                                      : "Racha: ${habit.streak}",
                                  style: TextStyle(
                                    color: itemSubColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Text(
                                  "📅 Evento",
                                  style: TextStyle(
                                    color: itemSubColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (habit.reminderTime != null &&
                                  !habit.isCompleted) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  habit.isAlarm
                                      ? Icons.alarm_rounded
                                      : Icons.notifications_active_rounded,
                                  size: 14,
                                  color: itemSubColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  habit.reminderTime!,
                                  style: TextStyle(
                                    color: itemSubColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: habit.isCompleted
                          ? Container(
                              decoration: BoxDecoration(
                                color: isLightColor
                                    ? Colors.black87
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                          : Icon(
                              Icons.circle_outlined,
                              size: 35,
                              color: subTextColor.withValues(alpha: 0.5),
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
  }
}
