import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginMode = true;
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  String selectedGender = "Prefiero no decirlo";

  // --- FUNCIÓN: Autenticación REAL con Correo/Contraseña ---
  Future<void> _handleEmailAuth() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena correo y contraseña.")),
      );
      return;
    }

    final provider = context.read<HabitProvider>();

    // FIX: Capturamos el navegador raíz antes del proceso asíncrono
    final nav = Navigator.of(context, rootNavigator: true);

    // Mostrar círculo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    String? errorMessage;

    if (isLoginMode) {
      errorMessage = await provider.signInWithEmail(email, password);
    } else {
      final name = nameCtrl.text.trim();
      final age = ageCtrl.text.trim();
      if (name.isEmpty) {
        nav.pop(); // Cerramos el círculo usando el navegador capturado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ingresa tu nombre para crear la cuenta."),
            ),
          );
        }
        return;
      }
      errorMessage = await provider.registerWithEmail(
        email,
        password,
        name,
        age.isEmpty ? "25" : age,
        selectedGender,
      );
    }

    // FIX: Cerramos el círculo de carga con seguridad sin depender de 'mounted'
    nav.pop();

    if (errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- FUNCIÓN GOOGLE ---
  Future<void> _handleGoogleSignIn() async {
    final provider = context.read<HabitProvider>();

    // FIX: Capturamos el navegador raíz
    final nav = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    await provider.authenticate();

    // FIX: Cerramos el círculo de carga mágicamente.
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.spa_rounded,
                  size: 80,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Bloom Your Day",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 32),

                // Selector Entrar/Registro
                Row(
                  children: [
                    _buildTab(
                      "Entrar",
                      isLoginMode,
                      () => setState(() => isLoginMode = true),
                    ),
                    _buildTab(
                      "Registro",
                      !isLoginMode,
                      () => setState(() => isLoginMode = false),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (!isLoginMode) ...[
                  _buildTextField(
                    nameCtrl,
                    "Nombre completo",
                    Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          ageCtrl,
                          "Edad",
                          Icons.cake_rounded,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
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
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => selectedGender = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                _buildTextField(
                  emailCtrl,
                  "Correo electrónico",
                  Icons.email_rounded,
                  isEmail: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  passCtrl,
                  "Contraseña",
                  Icons.lock_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleEmailAuth,
                  child: Text(
                    isLoginMode ? "Iniciar Sesión" : "Crear Cuenta",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildDivider(),
                const SizedBox(height: 24),

                _buildSocialButton(
                  "Continuar con Google",
                  Icons.g_mobiledata_rounded,
                  textColor,
                  _handleGoogleSignIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets de apoyo ---
  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTap();
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF2563EB) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? const Color(0xFF2563EB) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isNumber = false,
    bool isEmail = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: isNumber
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 50))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            " O usar métodos alternativos ",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 50))),
      ],
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
    );
  }
}
