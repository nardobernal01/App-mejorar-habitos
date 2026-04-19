import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Detecta el modo oscuro para ajustar los colores de las letras
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo decorativo con la hojita
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded, // Ícono de naturaleza/crecimiento
                size: 80,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 32),

            // Título principal
            Text(
              "Tu jardín está vacío",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Mensaje motivador
            Text(
              "Planta la semilla de tu primer hábito tocando el botón '+' de abajo. ¡Comienza a florecer tu día!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            // Flechita sutil apuntando al botón flotante
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}
