import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:habitechs/data/services/auth_service.dart';
import 'package:habitechs/presentation/providers/auth_provider.dart';
import 'package:habitechs/data/models/user.dart';
import 'package:iconsax/iconsax.dart';

// Definición local de colores
const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final AuthService _authService = AuthService();

  // Controladores
  final _nameController = TextEditingController();
  final _residentCodeController = TextEditingController();
  final _identityCardController = TextEditingController();
  final _occupationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  File? _newPhoto;
  bool _isLoading = false;
  // Usamos el modelo local del servicio para la carga inicial
  UserModel? _currentUserData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residentCodeController.dispose();
    _identityCardController.dispose();
    _occupationController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getMe();
      if (mounted) {
        setState(() {
          _currentUserData = user;
          // Cargar datos en los controladores
          _nameController.text = user.fullName;
          _residentCodeController.text = user.residentCode ?? '';
          _identityCardController.text = user.identityCard ?? '';
          _occupationController.text = user.occupation ?? '';
          _phoneController.text = user.phoneNumber ?? '';
          _secondaryPhoneController.text = user.secondaryPhoneNumber ?? '';
          _emailController.text = user.personalEmail ?? '';

          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newPhoto = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Enviar al Backend (Incluyendo el ResidentCode)
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        photo: _newPhoto,
        residentCode: _residentCodeController.text.trim(), // ✅ Se envía aquí
        identityCard: _identityCardController.text.trim(),
        occupation: _occupationController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        secondaryPhoneNumber: _secondaryPhoneController.text.trim(),
        personalEmail: _emailController.text.trim(),
      );

      // 2. Recargar datos frescos del Backend (esto trae los roles y datos actualizados)
      final updatedUser = await _authService.getMe();

      // 3. Convertir al modelo User global para actualizar el estado de la App
      final userForProvider = User(
        id: updatedUser.id,
        fullName: updatedUser.fullName,
        email: updatedUser.email,
        photoUrl: updatedUser.photoUrl,

        // ✅ CORRECCIÓN CRÍTICA: Asignamos los roles que vienen del backend.
        // Si esto se dejaba vacío, perdías el acceso de Admin.
        roles: updatedUser.roles,

        residentCode: updatedUser.residentCode,
        identityCard: updatedUser.identityCard,
        phoneNumber: updatedUser.phoneNumber,
        secondaryPhone: updatedUser.secondaryPhoneNumber,
        personalEmail: updatedUser.personalEmail,
      );

      // 4. Actualizar estado global (Refresca UI inmediatamente)
      ref.read(authProvider.notifier).updateUser(userForProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green),
        );
        context.pop(); // Regresar al Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoUrl = _currentUserData?.photoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- FOTO ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(color: kTeal, width: 2),
                              image: _newPhoto != null
                                  ? DecorationImage(
                                      image: FileImage(_newPhoto!),
                                      fit: BoxFit.cover)
                                  : (currentPhotoUrl != null &&
                                          currentPhotoUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(currentPhotoUrl),
                                          fit: BoxFit.cover)
                                      : null),
                            ),
                            child: (_newPhoto == null &&
                                    (currentPhotoUrl == null ||
                                        currentPhotoUrl.isEmpty))
                                ? const Icon(Iconsax.user,
                                    size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: kTeal, shape: BoxShape.circle),
                              child: const Icon(Iconsax.camera,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORMULARIO ---
                  _buildTextField(
                    controller: _nameController,
                    label: "Nombre Completo",
                    icon: Iconsax.user_edit,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _residentCodeController,
                    label: "Código de Residente",
                    icon: Iconsax.code,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _identityCardController,
                    label: "Cédula de Identidad",
                    icon: Iconsax.card,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _occupationController,
                    label: "Ocupación",
                    icon: Iconsax.briefcase,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _phoneController,
                    label: "Celular Personal",
                    icon: Iconsax.mobile,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _secondaryPhoneController,
                    label: "Celular Secundario",
                    icon: Iconsax.mobile,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: "Correo Electrónico Personal",
                    icon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 40),

                  // --- BOTÓN ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Guardar Cambios",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kTeal, width: 2),
        ),
      ),
    );
  }
}
