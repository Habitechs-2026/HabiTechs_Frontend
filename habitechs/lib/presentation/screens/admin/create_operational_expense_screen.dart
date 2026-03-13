import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:habitechs/presentation/providers/finance_provider.dart';
import 'package:iconsax/iconsax.dart';

class CreateOperationalExpenseScreen extends ConsumerStatefulWidget {
  const CreateOperationalExpenseScreen({super.key});

  @override
  ConsumerState<CreateOperationalExpenseScreen> createState() =>
      _CreateOperationalExpenseScreenState();
}

class _CreateOperationalExpenseScreenState
    extends ConsumerState<CreateOperationalExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  File? _proofImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      await ref.read(opExControllerProvider.notifier).createOpEx(
            title: _titleController.text,
            amount: amount,
            proofImage: _proofImage,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gasto registrado."), backgroundColor: Colors.green));
        context.pop(); // Volver al dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Gasto Operativo")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: "Asunto / Proveedor",
                    prefixIcon: Icon(Iconsax.tag)),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Monto (Bs)", prefixIcon: Icon(Iconsax.money)),
                validator: (v) => (double.tryParse(v!) ?? 0) <= 0
                    ? "Ingrese un monto válido"
                    : null,
              ),
              const SizedBox(height: 24),

              // Subida de Comprobante
              const Text("Comprobante (Factura/Recibo)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _proofImage != null
                      ? Image.file(_proofImage!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.camera, size: 40, color: Colors.grey),
                            Text("Adjuntar foto de la factura",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Iconsax.save_add, color: Colors.white),
                  label: const Text("Registrar Egreso",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.all(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
