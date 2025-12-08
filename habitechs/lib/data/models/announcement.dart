class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorEmail;
  final String? imageUrl; // ✅ NUEVO: Campo para la imagen

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorEmail,
    this.imageUrl, // ✅ NUEVO
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorEmail: json['authorEmail'] ?? 'Sistema',
      // ✅ NUEVO: Mapeamos la URL. Si el backend no la envía, será null.
      // Nota: Asegúrate de que tu Backend DTO envíe una propiedad llamada 'imageUrl' o similar.
      // Si en C# se llama 'ImageUrl', aquí json['imageUrl'] funcionará si usas las convenciones estándar,
      // o json['ImageUrl'] si no hay camelCase. Probamos con camelCase primero:
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
