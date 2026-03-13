import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitechs/main.dart';
import 'package:iconsax/iconsax.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Versión de la app
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre HabiTex'),
        backgroundColor: kOxfordBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Logo de HabiTex
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kTeal,
                    kTeal.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kTeal.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.home_hashtag,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Nombre de la app
            const Text(
              'HabiTex',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kOxfordBlue,
              ),
            ),

            const SizedBox(height: 8),

            // Versión
            Text(
              'Versión $appVersion (Build $buildNumber)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Descripción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kTeal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'HabiTex es una aplicación integral de gestión condominial diseñada específicamente para el mercado boliviano. '
                'Facilitamos la comunicación entre residentes, administradores y personal de seguridad, '
                'ofreciendo transparencia financiera, gestión de pagos, reservas de áreas comunes y mucho más.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Características principales
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Características principales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kOxfordBlue,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Iconsax.notification,
              title: 'Anuncios de la Comunidad',
              description:
                  'Mantente informado sobre eventos y avisos importantes.',
            ),

            _buildFeatureItem(
              icon: Iconsax.wallet_money,
              title: 'Gestión Financiera',
              description:
                  'Consulta tu estado de cuenta y realiza pagos de manera segura.',
            ),

            _buildFeatureItem(
              icon: Iconsax.calendar_1,
              title: 'Reservas de Áreas Comunes',
              description:
                  'Reserva salones de eventos, piscinas y otras amenidades.',
            ),

            _buildFeatureItem(
              icon: Iconsax.scan_barcode,
              title: 'Acceso con QR',
              description:
                  'Código QR personal para ingreso seguro al condominio.',
            ),

            _buildFeatureItem(
              icon: Iconsax.message_question,
              title: 'Sistema de Tickets',
              description:
                  'Reporta incidencias y realiza solicitudes de mantenimiento.',
            ),

            _buildFeatureItem(
              icon: Iconsax.shield_tick,
              title: 'Comunicación Directa',
              description:
                  'Chat con administración y seguridad en tiempo real.',
            ),

            const SizedBox(height: 32),

            // Información de contacto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kOxfordBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kOxfordBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kOxfordBlue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Empresa
                  _buildContactItem(
                    icon: Iconsax.building,
                    text: 'HabiTex S.R.L.',
                  ),

                  // Developer
                  _buildContactItem(
                    icon: Iconsax.code,
                    text: 'Javier Torrico (Developer)',
                  ),

                  // Teléfono (clickeable - copia al portapapeles)
                  InkWell(
                    onTap: () =>
                        _copyToClipboard(context, '+59177699097', 'Teléfono'),
                    child: _buildContactItem(
                      icon: Iconsax.call,
                      text: '+591 77699097',
                      isClickable: true,
                    ),
                  ),

                  // Email (clickeable - copia al portapapeles)
                  InkWell(
                    onTap: () => _copyToClipboard(
                        context, 'javiertorrico44@gmail.com', 'Email'),
                    child: _buildContactItem(
                      icon: Iconsax.sms,
                      text: 'javiertorrico44@gmail.com',
                      isClickable: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Text(
              '© 2024 HabiTex S.R.L.\nSanta Cruz de la Sierra, Bolivia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: kTeal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kOxfordBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isClickable ? kTeal : kOxfordBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isClickable ? kTeal : Colors.black87,
                decoration: isClickable ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (isClickable)
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: kTeal,
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        backgroundColor: kTeal,
      ),
    );
  }
}
