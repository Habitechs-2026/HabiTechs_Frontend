import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Colores de tu marca
const Color kOxfordBlue = Color(0xFF002147);
const Color kTeal = Colors.teal;

class HabiTexChatbot extends StatefulWidget {
  const HabiTexChatbot({super.key});

  @override
  State<HabiTexChatbot> createState() => _HabiTexChatbotState();
}

class _HabiTexChatbotState extends State<HabiTexChatbot> {
  // Ya no necesitamos la clave API ni librerías de IA, solo lógica local.
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida inicial (Local)
    _addMessage(
      "¡Hola! Soy tu asistente local de HabiTex. 🏠\nEstoy aquí para ayudarte con todas las funciones de la aplicación, incluyendo Anuncios, Contactos y Acceso.",
      false,
    );
  }

  void _addMessage(String text, bool isUser, {bool isError = false}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        isError: isError,
      ));
    });
    // Auto-scroll al último mensaje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _addMessage(text, true); // Mostrar mensaje del usuario
    setState(() => _isLoading = true);

    // Simular el tiempo de respuesta de la IA (para que no sea instantáneo)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 💡 MOTOR DE RESPUESTA LOCAL
    String response = _generateLocalResponse(text);

    _addMessage(response, false);

    setState(() => _isLoading = false);
  }

  // =========================================================
  // MOTOR DE REGLAS LOCALES (BASE DE CONOCIMIENTO AMPLIADA)
  // =========================================================
  String _generateLocalResponse(String query) {
    final lowerQuery = query.toLowerCase();

    // 1. FILTRO ESTRICTO (Temas No Permitidos)
    if (lowerQuery.contains("fútbol") ||
        lowerQuery.contains("política") ||
        lowerQuery.contains("chiste") ||
        lowerQuery.contains("otro tema") ||
        lowerQuery.contains("quién es") ||
        lowerQuery.contains("dime algo de") ||
        lowerQuery.contains("napoleón")) {
      return "Lo siento, como asistente de HabiTex, mi enfoque es estrictamente en temas relacionados con la gestión de tu condominio y el uso de la aplicación. Estoy aquí para ayudarte con el sistema de QR, Finanzas o Tickets. 🏠";
    }

    // 2. RESPUESTAS CENTRALES DE HabiTex (BASE AMPLIADA)

    // A. ACCESO / QR / VISITAS
    if (lowerQuery.contains("qr") ||
        lowerQuery.contains("acceso") ||
        lowerQuery.contains("visita")) {
      return "El sistema de Código QR está diseñado para gestionar el acceso de tus visitas de manera segura. Para usarlo, ve a la pestaña 'Mi QR'. Allí ingresas el nombre de la persona y la aplicación generará un código temporal que la seguridad escaneará al ingreso, registrando la visita automáticamente. Es un método seguro que garantiza que solo las personas autorizadas entren a tu unidad. 🛡️";
    }

    // B. FINANZAS / PAGOS / EXPENSAS
    if (lowerQuery.contains("pago") ||
        lowerQuery.contains("expensa") ||
        lowerQuery.contains("deuda") ||
        lowerQuery.contains("finanzas")) {
      return "Para revisar tus deudas o registrar un pago, navega a la pestaña 'Finanzas'. En esa sección, podrás ver tu estado de cuenta actual y el monto exacto de las expensas pendientes. Después de realizar una transferencia bancaria o pago con QR, usa la función de 'Registrar Comprobante' para que la administración pueda validar tu pago. Recuerda guardar siempre el comprobante como evidencia. 💸";
    }

    // C. RESERVAS (ÁREAS COMUNES)
    if (lowerQuery.contains("reserva") ||
        lowerQuery.contains("parrillero") ||
        lowerQuery.contains("piscina") ||
        lowerQuery.contains("salón")) {
      return "Puedes reservar cualquier área común (parrillero, piscina, salón de eventos) desde la pestaña 'Reservas'. Elige el área que deseas y selecciona una fecha disponible en el calendario. El sistema te mostrará qué días ya están ocupados, evitando conflictos. ¡Es muy fácil y rápido! 📅";
    }

    // D. TICKETS / RECLAMOS / PROBLEMAS
    if (lowerQuery.contains("ticket") ||
        lowerQuery.contains("reclamo") ||
        lowerQuery.contains("problema") ||
        lowerQuery.contains("falla")) {
      return "Si tienes un problema de mantenimiento o seguridad, ve a la pestaña 'Tickets' y crea un nuevo reporte. Proporciona un título claro y una descripción detallada. Si es posible, adjunta una foto. La administración recibirá tu reporte inmediatamente y podrá priorizar la solución.";
    }

    // E. ANUNCIOS
    if (lowerQuery.contains("anuncio") ||
        lowerQuery.contains("comunicado") ||
        lowerQuery.contains("aviso")) {
      return "Para ver los avisos y comunicados oficiales del condominio, navega a la pestaña 'Anuncios'. Allí la administración publica información relevante sobre mantenimiento, eventos, o cambios en las normas.";
    }

    // F. PERFIL Y CREDENCIALES
    if (lowerQuery.contains("perfil") ||
        lowerQuery.contains("credencial") ||
        lowerQuery.contains("entrar") ||
        lowerQuery.contains("login") ||
        lowerQuery.contains("contraseña")) {
      return "La gestión de tu perfil (foto y datos) se hace tocando tu foto/inicial en el menú lateral. Si olvidaste tu contraseña o tienes problemas para entrar, debes contactar a la administración de tu condominio para que te restablezcan el acceso.";
    }

    // G. CONTACTOS / DIRECTORIO
    if (lowerQuery.contains("contacto") ||
        lowerQuery.contains("administración") ||
        lowerQuery.contains("seguridad") ||
        lowerQuery.contains("directorio")) {
      return "Para contactar a la administración o seguridad, abre el Menú lateral (tres líneas en la esquina superior izquierda) y selecciona la opción 'Contactos'. Allí encontrarás números de teléfono y opciones de chat directo con el personal clave. 📞";
    }

    // 3. Saludos y Fallback
    if (lowerQuery.contains("hola") ||
        lowerQuery.contains("ayuda") ||
        lowerQuery.contains("gracias") ||
        lowerQuery.contains("info")) {
      return "¡Hola! Estoy listo para guiarte. ¿Qué te gustaría saber hoy? Puedo darte información detallada sobre QR, Pagos, Reservas, Tickets, Anuncios o Contactos.";
    }

    // 4. Fallback (Si no entiende nada)
    return "No pude entender tu consulta. Por favor, sé más específico sobre el tema de HabiTex que necesitas. Recuerda que puedo ayudarte con QR, Pagos, Reservas, Tickets, Anuncios o Contactos.";
  }

  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kOxfordBlue,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: kOxfordBlue, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Asistente HabiTex",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text("Asistencia Local",
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: msg.isError
                          ? Colors.red.shade100
                          : (msg.isUser ? kOxfordBlue : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: msg.isError
                          ? Border.all(color: Colors.red.shade300)
                          : null,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isError
                            ? Colors.red.shade900
                            : (msg.isUser ? Colors.white : Colors.black87),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kTeal)),
                  const SizedBox(width: 8),
                  Text("HabiTex está analizando...",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Escribe tu duda...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: kTeal,
                    elevation: 0,
                    mini: true,
                    // Icono de envío seguro
                    child: const Icon(Iconsax.send_1,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({required this.text, required this.isUser, this.isError = false});
}
