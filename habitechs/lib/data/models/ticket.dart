class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String requesterEmail;

  // --- NUEVOS CAMPOS ---
  final String? photoUrl; // Foto del residente
  final String? closingPhotoUrl; // Foto del admin/guardia
  final String? createdBy; // Nombre de quien creó
  final String? closedBy; // Nombre de quien cerró
  // --------------------

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.closedAt,
    required this.requesterEmail,
    this.photoUrl,
    this.closingPhotoUrl,
    this.createdBy,
    this.closedBy,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Abierto',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      closedAt:
          json['closedAt'] != null ? DateTime.tryParse(json['closedAt']) : null,
      requesterEmail: json['requesterEmail'] ?? '',

      // Mapeo seguro
      photoUrl: json['photoUrl'],
      closingPhotoUrl: json['closingPhotoUrl'],
      createdBy: json['createdBy'],
      closedBy: json['closedBy'],
    );
  }
}
