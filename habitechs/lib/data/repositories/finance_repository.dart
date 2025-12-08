import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/expense.dart';
import 'package:habitechs/data/models/payment_instruction_model.dart';
import 'package:habitechs/data/models/pending_approval.dart';
import 'package:habitechs/data/services/api_service.dart';
import 'package:intl/intl.dart';

class FinanceRepository {
  final Dio _dio;
  FinanceRepository(this._dio);

  // --- MÉTODOS AUXILIARES DE ERROR ---
  String _handleDioError(DioException e) {
    // Intenta leer el mensaje del backend (string)
    final errorMessage = e.response?.data is Map
        ? e.response?.data['message'] ?? 'Error desconocido del servidor.'
        : 'Error de red. Asegure que el servidor esté activo.';
    return errorMessage;
  }

  // --- MÉTODOS PARA EL RESIDENTE ---

  Future<List<Expense>> getMyDebt() async {
    try {
      final response = await _dio.get('/api/finance/my-debt');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Expense.fromJson(json)).toList();
      }
      throw Exception('Error al cargar deudas');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<PaymentInstructionModel> getPaymentInstructions() async {
    try {
      final response = await _dio.get('/api/finance/instructions');
      return PaymentInstructionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Registra el pago subiendo el comprobante (proofImage)
  Future<void> registerPayment(String expenseId, File proofImage) async {
    try {
      String fileName = proofImage.path.split('/').last;
      final formData = FormData.fromMap({
        'ProofImage':
            await MultipartFile.fromFile(proofImage.path, filename: fileName),
      });

      await _dio.post('/api/finance/$expenseId/report-payment', data: formData);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // --- MÉTODOS PARA EL ADMIN ---

  Future<List<Expense>> getAllExpenses() async {
    try {
      final response = await _dio.get('/api/finance/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Expense.fromJson(json)).toList();
      }
      throw Exception('Error al cargar todas las expensas');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Obtiene la lista de comprobantes pendientes de aprobación
  Future<List<PendingApproval>> getPendingApprovals() async {
    try {
      final response = await _dio.get('/api/finance/pending-approvals');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingApproval.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Acción: Marca el pago como APROBADO
  Future<void> approvePayment(String paymentId) async {
    try {
      await _dio.put('/api/finance/approve/$paymentId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Acción: Marca el pago como RECHAZADO
  Future<void> rejectPayment(String paymentId) async {
    try {
      await _dio.put('/api/finance/reject/$paymentId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Acción: Carga una nueva expensa (deuda)
  Future<void> createExpense(
      String email, String title, double amount, DateTime date) async {
    try {
      final response = await _dio.post(
        '/api/finance/charge',
        data: {
          'residentEmail': email,
          'title': title,
          'description': 'Cargo de administración',
          'amount': amount,
          'dueDate': DateFormat('yyyy-MM-dd').format(date),
        },
      );
      if (response.statusCode != 201) {
        throw Exception('Error al cargar expensa');
      }
    } on DioException catch (e) {
      // ✅ Utilizamos el manejador de errores corregido
      throw Exception(_handleDioError(e));
    }
  }

  // Método obsoleto pero mantenido
  Future<void> markExpenseAsPaid(String expenseId) async {
    try {
      final response = await _dio.put('/api/finance/$expenseId/mark-as-paid');
      if (response.statusCode != 200) {
        throw Exception('Error al marcar como pagado');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
}

final financeRepoProvider = Provider<FinanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FinanceRepository(dio);
});
