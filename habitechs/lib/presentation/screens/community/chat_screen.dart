import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:habitechs/presentation/providers/chat_provider.dart';
import 'package:iconsax/iconsax.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId; // ID con quien hablamos (Admin, Guardia, etc.)
  final String otherUserName; // Nombre para mostrar en el AppBar

  const ChatScreen(
      {super.key, required this.otherUserId, required this.otherUserName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // Función para enviar
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    ref
        .read(chatControllerProvider.notifier)
        .sendMessage(
          receiverId: widget.otherUserId,
          message: text.isNotEmpty ? text : null,
          image: _selectedImage,
        )
        .then((_) {
      // Limpiar inputs tras éxito
      _textController.clear();
      setState(() {
        _selectedImage = null;
      });
    });
  }

  // Seleccionar Imagen
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider(widget.otherUserId));
    final sendState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
            const Text('Se autoelimina en 30 días',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () =>
                  ref.invalidate(chatMessagesProvider(widget.otherUserId)),
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          // --- LISTA DE MENSAJES ---
          Expanded(
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text("Inicia la conversación..."));
                }
                return ListView.builder(
                  // Invertimos para que el último mensaje esté abajo (requiere ordenar la lista si el backend no la manda al revés)
                  // Pero como es chat standard, mejor lo pintamos normal y scrolleamos al final.
                  // Para simplificar, usaremos orden normal del backend (SentAt ascendente) y Reverse: false
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isMine ? Colors.teal : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: msg.isMine
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: msg.isMine
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Si tiene imagen
                            if (msg.imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    msg.imageUrl,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            // Texto
                            if (msg.message.isNotEmpty)
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: msg.isMine
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            // Fecha (opcional, muy pequeño)
                            const SizedBox(height: 4),
                            Text(
                              "${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 10,
                                color: msg.isMine
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // --- ÁREA DE INPUT ---
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Text("Imagen seleccionada"),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  )
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.camera, color: Colors.teal),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Enviar con Loading
                sendState.isLoading
                    ? const CircularProgressIndicator()
                    : CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _handleSend,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
