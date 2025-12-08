// Modelo para entender el JSON de GET /api/finance/...
class Expense {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String residentEmail;
  // ✅ NUEVO: Estado del último intento de pago reportado (PENDING, REJECTED, null)
  final String? lastPaymentStatus;

  Expense({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    required this.residentEmail,
    this.lastPaymentStatus, // Permitimos null
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isPaid: json['isPaid'] as bool,
      residentEmail: json['residentEmail'] as String,
      // ✅ Mapeamos el nuevo estado de pago
      lastPaymentStatus: json['lastPaymentStatus'] as String?,
    );
  }
}
