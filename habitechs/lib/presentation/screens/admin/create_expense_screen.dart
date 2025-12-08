import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/admin_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);
const Color kRed = Colors.red;

// Definición de la pantalla
class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String email = _emailController.text.trim();
      final String title = _titleController.text.trim();
      final double amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      // La lógica del provider manejará la conversión de DateTime a DateOnly/String para el Backend
      ref.read(expenseActionProvider.notifier).execute({
        'email': email,
        'title': title,
        'amount': amount,
        'date': _selectedDate,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(expenseActionProvider);

    ref.listen<AsyncValue<void>>(expenseActionProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        String errorMessage = next.error.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al crear expensa: $errorMessage'),
            backgroundColor: kRed));
      } else if (next.hasValue && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Expensa cargada exitosamente.'),
            backgroundColor: kTeal));
        _emailController.clear();
        _titleController.clear();
        _amountController.clear();
        ref.invalidate(
            allExpensesProvider); // Recargar la lista de expensas del admin
      }
    });

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Cargar Expensa", style: TextStyle(color: Colors.white)),
        backgroundColor: kOxfordBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email del Residente',
                  hintText: 'ej: javier5@gmail.com',
                  prefixIcon: Icon(Iconsax.user, color: kTeal),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Ingrese un email válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título (ej. Expensa Diciembre)',
                  hintText: 'Expensa Octubre',
                  prefixIcon: Icon(Iconsax.text_block, color: kTeal),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto (ej. 350.50)',
                  hintText: '500',
                  prefixIcon: Icon(Iconsax.money, color: kTeal),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final cleanedValue = value?.replaceAll(',', '.');
                  if (cleanedValue == null ||
                      double.tryParse(cleanedValue) == null ||
                      double.parse(cleanedValue) <= 0) {
                    return 'Ingrese un monto válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Selector de Fecha de Vencimiento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Fecha de Vencimiento:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, color: kTeal),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Seleccionar Fecha'),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: actionState.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: actionState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cargar Expensa',
                          style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
