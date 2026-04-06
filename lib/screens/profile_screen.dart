import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _exportData(HabitProvider provider) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    final String backupCode = provider.exportBackup();
    await Clipboard.setData(ClipboardData(text: backupCode));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Respaldo copiado al portapapeles! Guárdalo en un lugar seguro.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _importData(HabitProvider provider) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    final ClipboardData? clipboardData = await Clipboard.getData(
      Clipboard.kTextPlain,
    );

    if (!mounted) {
      return;
    }

    if (clipboardData != null &&
        clipboardData.text != null &&
        clipboardData.text!.isNotEmpty) {
      final bool success = provider.importBackup(clipboardData.text!);
      if (success) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Datos restaurados con éxito! Bienvenido de vuelta.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
        Navigator.pop(
          context,
        ); // Regresa a la pantalla principal para ver los cambios
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de respaldo inválido o corrupto.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay ningún código en tu portapapeles.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mi Perfil de Héroe",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // AVATAR Y NIVEL
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(
                      0xFFF59E0B,
                    ).withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 60,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nardo",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Nivel ${provider.playerLevel} • Maestro de Hábitos",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Experiencia",
                            style: TextStyle(
                              color: subTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${provider.playerXP} / ${provider.xpPerLevel} XP",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: provider.playerXP / provider.xpPerLevel,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          color: const Color(0xFFF59E0B),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // PANEL DE RESPALDO LOCAL
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Caja Fuerte (Respaldo)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_rounded,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    title: const Text(
                      "Exportar Respaldo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Genera un código con tu progreso"),
                    onTap: () => _exportData(provider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    title: const Text(
                      "Importar Respaldo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Pega el código para restaurar todo"),
                    onTap: () => _importData(provider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INSIGNIAS PRO Y BIOMETRÍA
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Estado de Cuenta",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: provider.isPremiumUnlocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                          : isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.isPremiumUnlocked
                            ? const Color(0xFFF59E0B)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 32,
                          color: provider.isPremiumUnlocked
                              ? const Color(0xFFF59E0B)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.isPremiumUnlocked ? "PRO Activo" : "Gratis",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: provider.useBiometrics
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.useBiometrics
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 32,
                          color: provider.useBiometrics
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.useBiometrics ? "Seguro" : "Sin Bloqueo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
