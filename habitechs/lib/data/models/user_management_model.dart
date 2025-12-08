class UserManagementModel {
  final String id;
  final String email;
  final String fullName;
  final List<String> roles;
  final bool isActive;

  UserManagementModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
    required this.isActive,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    return UserManagementModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? 'Sin Nombre',
      // Mapeamos los roles desde la respuesta del backend
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
    );
  }
}
