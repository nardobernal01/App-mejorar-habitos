import '../widgets/real_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/habit_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickImage(HabitProvider provider) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        provider.updateProfile(
          provider.userName,
          provider.userAge,
          provider.userGender,
          image.path,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al abrir la galería')),
      );
    }
  }

  void _showEditProfileDialog(HabitProvider provider) {
    SystemSound.play(SystemSoundType.click);
    final TextEditingController nameCtrl = TextEditingController(
      text: provider.userName,
    );
    final TextEditingController ageCtrl = TextEditingController(
      text: provider.userAge,
    );
    String selectedGender = provider.userGender;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                "Editar Perfil",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Edad",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        labelText: "Sexo",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                                "Masculino",
                                "Femenino",
                                "Prefiero no decirlo",
                                "Otro",
                              ]
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedGender = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    provider.updateProfile(
                      nameCtrl.text.trim(),
                      ageCtrl.text.trim(),
                      selectedGender,
                      provider.userPhotoPath,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyChart(
    HabitProvider provider,
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );
    int maxCompletions = 1;
    for (var day in last7Days) {
      final dateKey = DateTime(day.year, day.month, day.day);
      final count = provider.heatmapDatasets[dateKey] ?? 0;
      if (count > maxCompletions) {
        maxCompletions = count;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tu Semana",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hábitos completados en los últimos 7 días",
            style: TextStyle(color: subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const RealHeatmap(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "Mi Perfil",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              // --- NUEVO BOTÓN DE CERRAR SESIÓN CON ADVERTENCIA ---
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        "Cerrar Sesión",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        "¿Estás seguro de que deseas salir de tu cuenta?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx); // Cierra el diálogo
                            await provider.signOut();
                            if (!context.mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text("Salir"),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // --- BOTÓN DE EDITAR PERFIL ---
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _showEditProfileDialog(provider),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
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
                      GestureDetector(
                        onTap: () => _pickImage(provider),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 130,
                                height: 130,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child:
                                    (provider.userPhotoPath != null ||
                                        FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.photoURL !=
                                            null)
                                    ? Image.network(
                                        provider.userPhotoPath ??
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .photoURL!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 65,
                                                color: Colors.grey,
                                              );
                                            },
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 65,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.userName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${provider.userAge} años • ${provider.userGender}",
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Nivel ${provider.playerLevel} • Maestro",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
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
                                "${provider.currentLevelXP} / ${provider.xpPerLevel} XP",
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
                              value: provider.levelProgress,
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
                _buildWeeklyChart(
                  provider,
                  context,
                  isDark,
                  textColor,
                  subTextColor,
                ),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Comunidad y Soporte",
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
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        title: const Text(
                          "Califícanos en la Tienda",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          final InAppReview inAppReview = InAppReview.instance;
                          if (await inAppReview.isAvailable()) {
                            inAppReview.requestReview();
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        title: const Text(
                          "Compartir aplicación",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Share.share(
                          "¡Únete a Bloom Your Day y transforma tus hábitos conmigo! Descárgala ya.",
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bug_report_rounded,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        title: const Text(
                          "Informar de un error",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => launchUrl(
                          Uri.parse(
                            "mailto:soporte@bloomyourday.com?subject=Reporte%20de%20Error",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Seguridad y Suscripción",
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
                              provider.isPremiumUnlocked
                                  ? "PRO Activo"
                                  : "Gratis",
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
                    // --- NUEVO BOTÓN PRESIONABLE DE BIOMETRÍA ---
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          HapticFeedback.lightImpact();
                          provider.toggleBiometrics();
                        },
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
                                provider.useBiometrics
                                    ? "Seguro"
                                    : "Sin Bloqueo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
