// Archivo: lib/data/models/pending_approval.dart
import 'package:habitechs/data/models/expense.dart';

class PendingApproval {
  final String paymentId;
  final String residentEmail;
  final String proofImageUrl;
  final DateTime paymentDate;
  final Expense expense; // La deuda a la que corresponde este pago

  PendingApproval({
    required this.paymentId,
    required this.residentEmail,
    required this.proofImageUrl,
    required this.paymentDate,
    required this.expense,
  });

  factory PendingApproval.fromJson(Map<String, dynamic> json) {
    return PendingApproval(
      paymentId: json['paymentId'] as String,
      residentEmail: json['residentEmail'] as String,
      proofImageUrl: json['proofImageUrl'] as String,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      // Mapeamos la Expensa completa que viene anidada
      expense: Expense.fromJson(json['expense'] as Map<String, dynamic>),
    );
  }
}
