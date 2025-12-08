class User {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final List<String> roles;

  // --- ESTOS SON LOS CAMPOS QUE FALTABAN ---
  final String? residentCode;
  final String? identityCard;
  final String? phoneNumber;
  final String? secondaryPhone;
  final String? personalEmail;
  // -----------------------------------------

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.roles,
    this.residentCode,
    this.identityCard,
    this.phoneNumber,
    this.secondaryPhone,
    this.personalEmail,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      // Aseguramos que los roles se lean como lista de Strings
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],

      // Mapeo seguro de los nuevos campos
      residentCode: json['residentCode'],
      identityCard: json['identityCard'],
      phoneNumber: json['phoneNumber'],
      secondaryPhone: json['secondaryPhone'],
      personalEmail: json['personalEmail'],
    );
  }
}
