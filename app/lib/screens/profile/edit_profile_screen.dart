import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _telefonoController = TextEditingController(text: user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.updateProfile({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
      });

      if (success && mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUserData();
        SnackBarHelper.success(context, 'Perfil actualizado correctamente');
        Navigator.pop(context);
      } else if (mounted) {
        SnackBarHelper.error(context, 'Error al actualizar el perfil');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.error(context, 'Ocurrió un error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.richBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w900,
            color: AppColors.richBlack,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Perfil',
                  style: GoogleFonts.catamaran(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.richBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Actualiza tu información personal para mantener tu cuenta al día.',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    color: AppColors.sonicSilver,
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildTextField(
                  label: 'Nombre',
                  controller: _nombreController,
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  label: 'Apellido',
                  controller: _apellidoController,
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty ? 'Ingresa tu apellido' : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  label: 'Correo Electrónico',
                  controller: _emailController,
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  enabled: false,
                ),

                const SizedBox(height: 20),
                
                _buildTextField(
                  label: 'Teléfono',
                  controller: _telefonoController,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Guardar Cambios',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.richBlack.withOpacity(enabled ? 0.7 : 0.4),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          style: GoogleFonts.rubik(
            fontSize: 15,
            color: enabled ? AppColors.richBlack : AppColors.sonicSilver,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(enabled ? 0.7 : 0.3), size: 20),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.gainsboro.withOpacity(0.5), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
