import 'package:flutter/material.dart';

// --- MODELO DE DATOS ---
class TutorialStep {
  final GlobalKey key;
  final String title;
  final String description;
  final bool isMenuAction; // Si requiere abrir menú
  final bool insideMenu; // Si está DENTRO del menú
  final double? customPadding; // MEJORA: Padding personalizado por paso

  TutorialStep({
    required this.key,
    required this.title,
    required this.description,
    this.isMenuAction = false,
    this.insideMenu = false,
    this.customPadding,
  });
}

class TutorialOverlay extends StatelessWidget {
  final Offset targetPosition;
  final Size targetSize;
  final TutorialStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final AnimationController animController;

  const TutorialOverlay({
    super.key,
    required this.targetPosition,
    required this.targetSize,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double tooltipWidth = 280;
    const double margin = 20;

    // MEJORA: Usamos el padding personalizado si existe, sino el default (16)
    final double padding = step.customPadding ?? 16;

    double top = targetPosition.dy + targetSize.height + margin;
    double left =
        targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
    bool isTop = false;

    // Si se sale por abajo, poner arriba
    if (top + 200 > screenSize.height) {
      top = targetPosition.dy - 220; // Ajuste aproximado
      isTop = true;
    }

    // Ajustes laterales
    if (left < 20) left = 20;
    if (left + tooltipWidth > screenSize.width - 20) {
      left = screenSize.width - tooltipWidth - 20;
    }

    return Stack(
      children: [
        // 1. Fondo Oscuro con Agujero
        ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                top: targetPosition.dy - padding,
                left: targetPosition.dx - padding,
                child: Container(
                  width: targetSize.width + (padding * 2),
                  height: targetSize.height + (padding * 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Borde Animado (Foco)
        Positioned(
          top: targetPosition.dy - padding,
          left: targetPosition.dx - padding,
          child: AnimatedBuilder(
            animation: animController,
            builder: (context, child) {
              return Container(
                width: targetSize.width + (padding * 2),
                height: targetSize.height + (padding * 2),
                decoration: BoxDecoration(
                    // MEJORA: Radio de borde más suave
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2DD4BF)
                          .withOpacity(1.0 - animController.value),
                      // MEJORA: Borde un poco más grueso y difuso para efecto premium
                      width: 3 + (animController.value * 6),
                    ),
                    // MEJORA: Sutil sombra interna/externa para dar profundidad
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF)
                            .withOpacity(0.3 * (1.0 - animController.value)),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]),
              );
            },
          ),
        ),

        // 3. Tarjeta de Texto
        Positioned(
          top: top,
          left: left,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: tooltipWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(step.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF001E35))),
                      Text("$stepIndex/$totalSteps",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(step.description,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF64748B), height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: onSkip,
                          child: const Text("Saltar",
                              style: TextStyle(color: Colors.grey))),
                      ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(stepIndex == totalSteps
                            ? "Finalizar"
                            : "Siguiente"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
