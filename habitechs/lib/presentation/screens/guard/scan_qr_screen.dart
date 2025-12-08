import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/scan_provider.dart';
import 'package:habitechs/presentation/screens/guard/validate_visit_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanComplete = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Si el widget ya no existe o ya completamos un escaneo, paramos.
    if (!mounted || _isScanComplete) return;

    final String? code = capture.barcodes.first.rawValue;

    if (code != null) {
      setState(() => _isScanComplete = true);

      // 1. Detectar si es PASE DE VISITA (JSON)
      try {
        final decoded = jsonDecode(code);
        if (decoded is Map && decoded['type'] == 'visit_pass') {
          // Pausa la cámara antes de navegar
          _scannerController.stop();

          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ValidateVisitScreen(qrData: code),
            ),
          );

          // Al volver, reactivamos
          if (mounted) {
            _scannerController.start();
            setState(() => _isScanComplete = false);
          }
          return;
        }
      } catch (_) {
        // No es JSON, continuamos
      }

      // 2. QR ANTIGUO (Texto simple)
      ref.read(scanActionProvider.notifier).checkInVisit(code);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de Visita')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isScanComplete)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: scanState.when(
                  loading: () =>
                      const CircularProgressIndicator(color: Colors.white),
                  error: (e, s) => _buildResult(
                    context,
                    'assets/animations/error.json',
                    "Error: ${e.toString()}",
                    Colors.red,
                  ),
                  data: (message) {
                    if (message == null) return const SizedBox.shrink();
                    return _buildResult(
                      context,
                      'assets/animations/success.json',
                      message,
                      Colors.green,
                    );
                  },
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildResult(
      BuildContext context, String lottieAsset, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(lottieAsset, width: 150, repeat: false),
          const SizedBox(height: 20),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(scanActionProvider.notifier).reset();
              if (mounted) setState(() => _isScanComplete = false);
            },
            child: const Text('Escanear Siguiente'),
          )
        ],
      ),
    );
  }
}
