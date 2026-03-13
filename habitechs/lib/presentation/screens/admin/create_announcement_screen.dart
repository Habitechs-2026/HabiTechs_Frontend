import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/admin_provider.dart'; // Importa el provider genérico

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});
  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(announcementActionProvider.notifier).execute({
      'title': _titleController.text,
      'content': _contentController.text,
    });
    if (mounted && !ref.read(announcementActionProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Anuncio Publicado!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementActionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Anuncio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 16),
            TextField(
                controller: _contentController,
                decoration:
                    const InputDecoration(labelText: 'Contenido del anuncio'),
                maxLines: 5),
            const SizedBox(height: 24),
            if (state.hasError)
              Text("Error: ${state.error.toString()}",
                  style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
