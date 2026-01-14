import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_model.dart';

class CreateEditClassScreen extends StatefulWidget {
  final ClassModel? clase; // Si es null, es crear; si tiene valor, es editar

  const CreateEditClassScreen({super.key, this.clase});

  @override
  State<CreateEditClassScreen> createState() => _CreateEditClassScreenState();
}

class _CreateEditClassScreenState extends State<CreateEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _duracionController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.clase != null) {
      // Modo edición: cargar datos existentes
      _nombreController.text = widget.clase!.nombre;
      _descripcionController.text = widget.clase!.descripcion ?? '';
      _capacidadController.text = widget.clase!.capacidadMaxima?.toString() ?? '';
      _duracionController.text = widget.clase!.duracionMinutos?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.clase == null) {
        // Crear nueva clase
        result = await _apiService.createClass(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          capacidadMaxima: _capacidadController.text.trim().isEmpty
              ? null
              : int.tryParse(_capacidadController.text.trim()),
          duracionMinutos: _duracionController.text.trim().isEmpty
              ? null
              : int.tryParse(_duracionController.text.trim()),
        );
      } else {
        // Actualizar clase existente
        result = await _apiService.updateClass(
          id: widget.clase!.id,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          capacidadMaxima: _capacidadController.text.trim().isEmpty
              ? null
              : int.tryParse(_capacidadController.text.trim()),
          duracionMinutos: _duracionController.text.trim().isEmpty
              ? null
              : int.tryParse(_duracionController.text.trim()),
          activo: widget.clase!.activo,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.clase == null
                    ? 'Clase creada exitosamente'
                    : 'Clase actualizada exitosamente',
                style: GoogleFonts.rubik(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true); // Retornar true para indicar éxito
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    (widget.clase == null
                        ? 'Error al crear la clase'
                        : 'Error al actualizar la clase'),
                style: GoogleFonts.rubik(),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de conexión: ${e.toString()}',
              style: GoogleFonts.rubik(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.clase == null ? 'Nueva Clase' : 'Editar Clase',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.richBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveClass,
              child: Text(
                'Guardar',
                style: GoogleFonts.rubik(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clase == null
                                ? 'Crear Nueva Clase'
                                : 'Editar Clase',
                            style: GoogleFonts.catamaran(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.richBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa la información de la clase',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              color: AppColors.sonicSilver,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nombre Field
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre de la clase',
                hint: 'Ej: Yoga Matutino',
                icon: Icons.title,
                required: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de la clase es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción Field
              _buildTextField(
                controller: _descripcionController,
                label: 'Descripción',
                hint: 'Describe la clase y sus beneficios...',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Configuración Section
              _buildSectionTitle('Configuración'),
              const SizedBox(height: 12),

              // Capacidad
              _buildTextField(
                controller: _capacidadController,
                label: 'Capacidad máxima',
                hint: 'Ej: 20',
                icon: Icons.people,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final capacidad = int.tryParse(value.trim());
                    if (capacidad == null || capacidad < 1) {
                      return 'Debe ser mayor a 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duración
              _buildTextField(
                controller: _duracionController,
                label: 'Duración (minutos)',
                hint: 'Ej: 60',
                icon: Icons.access_time,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final duracion = int.tryParse(value.trim());
                    if (duracion == null || duracion < 15) {
                      return 'Mínimo 15 minutos';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los campos marcados con * son obligatorios. Puedes agregar horarios después de crear la clase.',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: AppColors.richBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button (Bottom)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.clase == null ? 'Crear Clase' : 'Guardar Cambios',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              // Espacio adicional para evitar que se sobreponga con el menú de navegación del teléfono
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.catamaran(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.richBlack,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.rubik(
          fontSize: 15,
          color: AppColors.richBlack,
        ),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          hintStyle: GoogleFonts.rubik(
            color: AppColors.sonicSilver.withOpacity(0.6),
          ),
          labelStyle: GoogleFonts.rubik(
            color: AppColors.sonicSilver,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.lightGray,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.lightGray,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 16,
          ),
        ),
      ),
    );
  }
}
