import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Para capturar imagen
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/auth_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // Para guardar imagen
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// Provider local para guardar el String del QR (el JSON)
final qrDataProvider = StateProvider.autoDispose<String?>((ref) => null);

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  final _nameController = TextEditingController();
  final _ciController = TextEditingController();

  // ✅ CORRECCIÓN 1: La Key debe ser parte del Estado, no global
  final GlobalKey _qrKey = GlobalKey();

  // Variables para ENTRADA
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Variables para SALIDA
  DateTime? _exitDate;
  TimeOfDay? _exitTime;

  @override
  void dispose() {
    _nameController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FECHAS ---
  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        return DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
      }
    }
    return null;
  }

  Future<void> _selectEntryDate() async {
    final dt = await _pickDateTime(context, DateTime.now());
    if (dt != null) {
      setState(() => _selectedDate = dt);
      if (_exitDate == null) {
        setState(() => _exitDate = dt.add(const Duration(hours: 4)));
      }
    }
  }

  Future<void> _selectExitDate() async {
    final initial = _selectedDate ?? DateTime.now();
    final dt = await _pickDateTime(context, initial);
    if (dt != null) {
      setState(() => _exitDate = dt);
    }
  }

  // --- GENERAR QR ---
  void _generate() {
    if (_nameController.text.trim().isEmpty) return _showError('Falta nombre');
    if (_ciController.text.trim().isEmpty) return _showError('Falta CI');
    if (_selectedDate == null) return _showError('Falta entrada');
    if (_exitDate == null) return _showError('Falta salida');

    if (_exitDate!.isBefore(_selectedDate!)) {
      return _showError('La salida no puede ser antes de la entrada');
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null)
      return _showError('No se encontró info del residente');

    final Map<String, dynamic> qrDataMap = {
      'type': 'visit_pass',
      'v_name': _nameController.text.trim(),
      'v_ci': _ciController.text.trim(),
      'entry': _selectedDate!.toIso8601String(),
      'exit': _exitDate!.toIso8601String(),
      'r_name': currentUser.fullName,
      'r_code': currentUser.residentCode ?? 'N/A',
      'r_id': currentUser.id,
      'created_at': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(qrDataMap);
    ref.read(qrDataProvider.notifier).state = jsonString;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // --- FUNCIÓN COMPARTIR IMAGEN CORREGIDA ---
  Future<void> _shareQrImage() async {
    try {
      // ✅ CORRECCIÓN 2: Pequeña espera para asegurar que el QR se dibujó
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint(
            "Error: Boundary es nulo. El widget no está visible o no tiene Key.");
        _showError("No se pudo capturar el QR. Intenta de nuevo.");
        return;
      }

      // 1. Capturar imagen
      // Nota: Si falla aquí, a veces es porque el QR aun se está pintando
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception("Error al convertir imagen");

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Guardar archivo temporal
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pase_visita.png');
      await file.writeAsBytes(pngBytes);

      // 3. Compartir
      // Usamos el contexto para ubicar el popover en iPad (opcional pero bueno)
      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '¡Hola! Aquí tienes tu pase de ingreso a HabiTex.',
        subject: 'Pase de Visita',
        sharePositionOrigin:
            box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
      );
    } catch (e) {
      debugPrint('ERROR AL COMPARTIR: $e');
      _showError('Error al generar la imagen: $e');
    }
  }

  void _reset() {
    _nameController.clear();
    _ciController.clear();
    setState(() {
      _selectedDate = null;
      _exitDate = null;
    });
    ref.read(qrDataProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final qrData = ref.watch(qrDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: qrData == null
              ? _buildForm(context)
              : _buildQrResult(context, qrData),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    String entryLabel = _selectedDate == null
        ? 'Fecha/Hora Entrada'
        : DateFormat('dd/MM - HH:mm').format(_selectedDate!);

    String exitLabel = _exitDate == null
        ? 'Fecha/Hora Salida'
        : DateFormat('dd/MM - HH:mm').format(_exitDate!);

    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(Iconsax.scan_barcode, size: 60, color: Colors.teal),
          const SizedBox(height: 10),
          const Text('Crear Pase de Visita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Ingresa los datos de tu invitado',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Iconsax.user)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ciController,
            decoration: const InputDecoration(
                labelText: 'Cédula de Identidad (CI)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Iconsax.card)),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectEntryDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Entrada',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.calendar_1)),
                    child: Text(entryLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _selectExitDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Salida',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.calendar_tick)),
                    child: Text(exitLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: _exitDate == null
                                ? Colors.grey
                                : Colors.black)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white),
            onPressed: _generate,
            child: const Text('Generar Código QR'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrResult(BuildContext context, String qrData) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('¡Pase Generado!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
          const SizedBox(height: 20),

          // --- ÁREA CAPTURABLE ---
          // Ponemos fondo blanco explícito para que la imagen salga bien
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco obligatorio para la foto
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("PASE DE INGRESO",
                      style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(_nameController.text,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center),
                  Text("CI: ${_ciController.text}",
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _smallInfo("ENTRADA",
                          DateFormat('dd/MM HH:mm').format(_selectedDate!)),
                      _smallInfo("SALIDA",
                          DateFormat('dd/MM HH:mm').format(_exitDate!)),
                    ],
                  )
                ],
              ),
            ),
          ),
          // ------------------------

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: _shareQrImage,
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Compartir Imagen (WhatsApp)',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50)),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Nuevo Pase'),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
