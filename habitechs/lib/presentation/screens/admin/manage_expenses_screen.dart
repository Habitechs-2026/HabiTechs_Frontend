import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/admin_provider.dart';
import 'package:lottie/lottie.dart';

class ManageExpensesScreen extends ConsumerWidget {
  const ManageExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Pagos (Simulado)'),
      ),
      body: expensesAsync.when(
        loading: () => Center(
            child: Lottie.asset('assets/animations/loading.json', width: 150)),
        error: (e, s) => Center(child: Text('Error: ${e.toString()}')),
        data: (expenses) {
          final pendingExpenses = expenses.where((e) => !e.isPaid).toList();

          if (pendingExpenses.isEmpty) {
            return const Center(child: Text('No hay deudas pendientes.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allExpensesProvider),
            child: ListView.builder(
              itemCount: pendingExpenses.length,
              itemBuilder: (context, index) {
                final expense = pendingExpenses[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(expense.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Deudor: ${expense.residentEmail}\nMonto: ${expense.amount} BOB'),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Marcar Pagado',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ref
                            .read(markAsPaidActionProvider.notifier)
                            .execute({'id': expense.id});
                        // Refrescar ambas listas
                        ref.invalidate(allExpensesProvider);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
