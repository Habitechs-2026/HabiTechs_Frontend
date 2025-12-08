import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ✅ Agregado para navegar al chat
import 'package:lottie/lottie.dart';
import 'package:habitechs/presentation/providers/auth_provider.dart';
import 'package:iconsax/iconsax.dart'; // ✅ Agregado para el ícono

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  // Variable para controlar si se ve la contraseña
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LOGIN REAL
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Por favor ingresa email y contraseña.";
      });
      return;
    }

    // Llamada al Backend
    final errorString = await ref.read(authProvider.notifier).login(
          email,
          password,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (errorString != null) {
        _errorMessage = errorString;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ NUEVO: Botón Flotante del Asistente IA (Solo aparece aquí)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar al chatbot sin necesidad de login
          context.push('/chatbot');
        },
        backgroundColor:
            Colors.teal, // Color diferente al de Ingresar para destacar
        icon: const Icon(Iconsax.message_question, color: Colors.white),
        label: const Text(
          "¿Necesitas ayuda?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animación Lottie (Edificio)
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset('assets/animations/login_building.json'),
              ),
              const SizedBox(height: 20),

              // --- TÍTULO ACTUALIZADO ---
              Text(
                '¡Bienvenido a HabiTex!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF002147), // Azul Oxford
                    ),
              ),
              const SizedBox(height: 30),

              // Campo Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Campo Contraseña con "Ojito"
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: _errorMessage,
                  // --- AQUÍ ESTÁ EL OJITO ---
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                // Esto controla si se oculta o no el texto
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 30),

              // Botón de Ingreso
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _login,
                      child: const Text('Ingresar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
