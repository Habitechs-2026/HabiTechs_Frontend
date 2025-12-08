import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitechs/data/repositories/access_repository.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ValidateVisitScreen extends ConsumerStatefulWidget {
  final String qrData; // El string JSON escaneado

  const ValidateVisitScreen({super.key, required this.qrData});

  @override
  ConsumerState<ValidateVisitScreen> createState() =>
      _ValidateVisitScreenState();
}

class _ValidateVisitScreenState extends ConsumerState<ValidateVisitScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseQrData();
  }

  void _parseQrData() {
    try {
      final decoded = jsonDecode(widget.qrData);
      if (decoded is Map<String, dynamic> && decoded['type'] == 'visit_pass') {
        setState(() => _data = decoded);
      } else {
        setState(() => _errorMessage = 'Formato de QR inválido');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al leer el QR');
    }
  }

  Future<void> _processAccess(bool isApproved) async {
    if (_data == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(accessRepoProvider);
      // Llamamos al backend con la data y la decisión del guardia
      final message = await repo.processVisitAccess(
        qrDataMap: _data!,
        isApproved: isApproved,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: isApproved ? Colors.green : Colors.red),
        );
        context.pop(); // Volver a la pantalla de escaneo
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error de Validación')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => context.pop(), child: const Text('Volver'))
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Formatear fechas para mostrar
    final entry = DateTime.parse(_data!['entry']);
    final exit = DateTime.parse(_data!['exit']);
    final now = DateTime.now();
    final isExpired = now.isAfter(exit);
    final isTooEarly = now.isBefore(
        entry.subtract(const Duration(minutes: 30))); // Margen de 30 min

    return Scaffold(
      appBar: AppBar(title: const Text('Validar Acceso de Visita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN 1: DATOS DEL VISITANTE ---
            _buildInfoCard(
              title: 'Datos del Visitante',
              icon: Iconsax.user_tag,
              color: Colors.blue,
              children: [
                _infoRow('Nombre:', _data!['v_name'], isBold: true),
                _infoRow('Cédula (CI):', _data!['v_ci'], isBold: true),
              ],
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN 2: HORARIOS Y ESTADO ---
            _buildInfoCard(
              title: 'Horario Programado',
              icon: Iconsax.calendar_tick,
              color: isExpired
                  ? Colors.red
                  : (isTooEarly ? Colors.orange : Colors.green),
              children: [
                _infoRow('Entrada:', DateFormat('dd/MM HH:mm').format(entry)),
                _infoRow('Salida:', DateFormat('dd/MM HH:mm').format(exit)),
                const Divider(),
                if (isExpired)
                  const Text('⚠️ PASE VENCIDO',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))
                else if (isTooEarly)
                  const Text('⚠️ MUY TEMPRANO',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))
                else
                  const Text('✅ HORARIO VÁLIDO',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN 3: DATOS DEL RESIDENTE (ANFITRIÓN) ---
            _buildInfoCard(
              title: 'Anfitrión (Residente)',
              icon: Iconsax.home_wifi,
              color: Colors.teal,
              children: [
                _infoRow('Nombre:', _data!['r_name']),
                _infoRow('Código:', _data!['r_code']),
              ],
            ),
            const SizedBox(height: 24),

            // --- BOTONES DE ACCIÓN ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processAccess(false), // RECHAZAR
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.block),
                      label: const Text('RECHAZAR INGRESO'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      // Solo habilitar si el horario es válido, o forzarlo
                      onPressed: (isExpired || isTooEarly)
                          ? null
                          : () => _processAccess(true), // APROBAR
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('PERMITIR ACCESO'),
                    ),
                  ),
                ],
              ),
            if (isExpired || isTooEarly)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton.icon(
                  onPressed: () => _processAccess(true), // APROBAR FORZADO
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange)),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Forzar Acceso (Bajo responsabilidad)'),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required Color color,
      required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5), width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color))
            ]),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
