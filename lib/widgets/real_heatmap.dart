import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealHeatmap extends StatefulWidget {
  const RealHeatmap({super.key});

  @override
  State<RealHeatmap> createState() => _RealHeatmapState();
}

class _RealHeatmapState extends State<RealHeatmap> {
  DateTime _selectedMonth = DateTime.now();

  // Función para cambiar de mes con las flechas
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Detecta automáticamente si el teléfono está en modo oscuro
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    // Calculamos cuántos días tiene el mes seleccionado
    int daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    List<DateTime> days = List.generate(
      daysInMonth,
      (index) => DateTime(_selectedMonth.year, _selectedMonth.month, index + 1),
    );

    const monthNames = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    String monthTitle =
        "${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('completion_history')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }

        // Traducimos los datos de Firebase a un mapa rápido
        Map<DateTime, int> historyData = {};
        int maxCompletions = 1;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('date') && data.containsKey('count')) {
              DateTime date = (data['date'] as Timestamp).toDate();
              int count = data['count'];
              if (count > 0) {
                DateTime cleanDate = DateTime(date.year, date.month, date.day);
                historyData[cleanDate] = count;
                if (count > maxCompletions) {
                  maxCompletions = count;
                }
              }
            }
          }
        }

        // Si ha hecho muy pocos hábitos, fijamos un techo visual para que la barra no se vea gigante con 1 solo hábito
        if (maxCompletions < 5) maxCompletions = 5;

        return Card(
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABECERA: Título y Selector de Mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Tu Progreso",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Si no cabe, pone "..."
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize
                          .min, // Evita que esta fila se expanda de más
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => _changeMonth(-1),
                          visualDensity: VisualDensity
                              .compact, // Reduce el ancho invisible del botón
                        ),
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => _changeMonth(1),
                          visualDensity: VisualDensity
                              .compact, // Reduce el ancho invisible del botón
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // LA GRÁFICA DE BARRAS CLÁSICA (Scroll horizontal)
                SizedBox(
                  height: 150, // Altura de la zona de gráfica
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    // Empezar el scroll al final si estamos en el mes actual para ver el día de hoy
                    reverse: false,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final int count = historyData[day] ?? 0;
                      final double percentage = (count / maxCompletions).clamp(
                        0.0,
                        1.0,
                      );

                      final now = DateTime.now();
                      final bool isToday =
                          day.day == now.day &&
                          day.month == now.month &&
                          day.year == now.year;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Etiqueta flotante si hizo algo ese día
                            if (count > 0)
                              Text(
                                "$count",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            const SizedBox(height: 4),

                            // Barra visual
                            Tooltip(
                              message:
                                  "$count completados el ${day.day} de ${monthNames[day.month - 1]}",
                              child: Container(
                                height: 100,
                                width: 24,
                                alignment: Alignment.bottomCenter,
                                decoration: BoxDecoration(
                                  // Usamos withValues como pidió tu Linter
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isToday
                                      ? Border.all(
                                          color: const Color(0xFF10B981),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: FractionallySizedBox(
                                  heightFactor: percentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isToday && count == 0
                                          ? Colors.transparent
                                          : const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Número del día abajo
                            Text(
                              "${day.day}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? const Color(0xFF10B981)
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
