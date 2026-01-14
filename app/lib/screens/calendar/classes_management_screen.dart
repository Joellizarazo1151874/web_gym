import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_model.dart';
import 'create_edit_class_screen.dart';

class ClassesManagementScreen extends StatefulWidget {
  const ClassesManagementScreen({super.key});

  @override
  State<ClassesManagementScreen> createState() =>
      _ClassesManagementScreenState();
}

class _ClassesManagementScreenState extends State<ClassesManagementScreen> {
  final ApiService _apiService = ApiService();
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  /// Validar formato de hora HH:MM
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// Validar que hora fin sea mayor que hora inicio
  bool _isValidTimeRange(String horaInicio, String horaFin) {
    try {
      final inicioParts = horaInicio.split(':');
      final finParts = horaFin.split(':');
      final inicioMinutes = int.parse(inicioParts[0]) * 60 + int.parse(inicioParts[1]);
      final finMinutes = int.parse(finParts[0]) * 60 + int.parse(finParts[1]);
      return finMinutes > inicioMinutes;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('📚 Cargando clases...');
      final classes = await _apiService.getClasses();
      print('📚 Clases recibidas: ${classes.length}');
      
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar clases: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar clases: ${e.toString()}',
              style: GoogleFonts.rubik(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCreateClassDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditClassScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadClasses();
    }
  }

  Future<void> _showEditClassDialog(ClassModel clase) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditClassScreen(clase: clase),
      ),
    );

    if (result == true && mounted) {
      _loadClasses();
    }
  }

  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Guía de Gestión de Clases',
                style: GoogleFonts.catamaran(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.richBlack,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.visibility,
                title: 'Visibilidad de las Clases',
                description:
                    'Las clases que crees serán visibles para TODOS los usuarios del gimnasio en el calendario. Asegúrate de crear clases con información clara y completa.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.schedule,
                title: 'Horarios de las Clases',
                description:
                    'Después de crear una clase, podrás agregar múltiples horarios para diferentes días de la semana. Cada horario aparecerá en el calendario de los usuarios.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.edit,
                title: 'Editar o Eliminar',
                description:
                    'Puedes editar o eliminar tus clases en cualquier momento. Ten en cuenta que al eliminar una clase, también se eliminarán todos sus horarios asociados.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.people,
                title: 'Capacidad y Duración',
                description:
                    'Define la capacidad máxima de participantes y la duración de cada sesión. Esta información ayudará a los usuarios a planificar su asistencia.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Crea clases descriptivas con nombres claros para que los usuarios puedan encontrarlas fácilmente.',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: AppColors.richBlack,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: GoogleFonts.rubik(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.catamaran(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.richBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  color: AppColors.sonicSilver,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteClassDialog(ClassModel clase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Clase',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la clase "${clase.nombre}"?\n\nEsta acción eliminará también todos los horarios asociados y no se puede deshacer.',
          style: GoogleFonts.rubik(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.rubik(color: AppColors.sonicSilver),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.rubik(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final result = await _apiService.deleteClass(clase.id);

        if (mounted) {
          Navigator.pop(context);

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Clase eliminada exitosamente',
                  style: GoogleFonts.rubik(),
                ),
                backgroundColor: AppColors.success,
              ),
            );
            _loadClasses();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Error al eliminar la clase',
                  style: GoogleFonts.rubik(),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
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
  }

  Future<void> _showAddScheduleDialog(ClassModel clase) async {
    int? selectedDay = 1;
    final horaInicioController = TextEditingController();
    final horaFinController = TextEditingController();

    // Guardar el contexto de la pantalla principal antes de mostrar el diálogo
    final scaffoldContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Agregar Horario',
            style: GoogleFonts.catamaran(
              fontWeight: FontWeight.w800,
              color: AppColors.richBlack,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clase: ${clase.nombre}',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w600,
                    color: AppColors.richBlack,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Día de la semana *',
                    labelStyle: GoogleFonts.rubik(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text('Lunes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 2, child: Text('Martes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 3, child: Text('Miércoles', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 4, child: Text('Jueves', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 5, child: Text('Viernes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 6, child: Text('Sábado', style: GoogleFonts.rubik())),
                    DropdownMenuItem(value: 7, child: Text('Domingo', style: GoogleFonts.rubik())),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDay = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: horaInicioController,
                  decoration: InputDecoration(
                    labelText: 'Hora inicio (HH:MM) *',
                    labelStyle: GoogleFonts.rubik(),
                    hintText: '08:00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: horaFinController,
                  decoration: InputDecoration(
                    labelText: 'Hora fin (HH:MM) *',
                    labelStyle: GoogleFonts.rubik(),
                    hintText: '09:00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.rubik(color: AppColors.sonicSilver),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final horaInicio = horaInicioController.text.trim();
                final horaFin = horaFinController.text.trim();

                if (horaInicio.isEmpty || horaFin.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Las horas son requeridas',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Validar formato de hora
                if (!_isValidTimeFormat(horaInicio)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Formato de hora inicio inválido. Use HH:MM (ej: 08:00)',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (!_isValidTimeFormat(horaFin)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Formato de hora fin inválido. Use HH:MM (ej: 09:00)',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Validar que hora fin sea mayor que hora inicio
                if (!_isValidTimeRange(horaInicio, horaFin)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'La hora de fin debe ser mayor que la hora de inicio',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Cerrar el diálogo primero
                Navigator.pop(dialogContext);

                if (!mounted) return;

                showDialog(
                  context: scaffoldContext,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final result = await _apiService.createClassSchedule(
                    claseId: clase.id,
                    diaSemana: selectedDay!,
                    horaInicio: horaInicio,
                    horaFin: horaFin,
                  );

                  if (mounted) {
                    Navigator.pop(scaffoldContext);

                    if (result['success'] == true) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                      'Horario agregado exitosamente',
                      style: GoogleFonts.rubik(),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Recargar clases para actualizar el contador de horarios
                _loadClasses();
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Error al crear el horario',
                            style: GoogleFonts.rubik(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(scaffoldContext);
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Agregar',
                style: GoogleFonts.rubik(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gestión de Clases',
              style: GoogleFonts.catamaran(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.richBlack,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showHelpDialog,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.richBlack),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: _classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: AppColors.lightGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay clases creadas',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              color: AppColors.sonicSilver,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para crear una',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              color: AppColors.sonicSilver,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        final clase = _classes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        clase.nombre,
                                        style: GoogleFonts.catamaran(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.richBlack,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: clase.activo
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        clase.activo ? 'Activa' : 'Inactiva',
                                        style: GoogleFonts.rubik(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: clase.activo
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (clase.descripcion != null &&
                                    clase.descripcion!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    clase.descripcion!,
                                    style: GoogleFonts.rubik(
                                      fontSize: 14,
                                      color: AppColors.sonicSilver,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (clase.capacidadMaxima != null)
                                      _buildInfoChip(
                                        Icons.people,
                                        'Capacidad: ${clase.capacidadMaxima}',
                                      ),
                                    if (clase.duracionMinutos != null)
                                      _buildInfoChip(
                                        Icons.access_time,
                                        'Duración: ${clase.duracionMinutos} min',
                                      ),
                                    _buildInfoChip(
                                      Icons.schedule,
                                      'Horarios: ${clase.totalHorarios}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/class_schedules',
                                            arguments: clase,
                                          );
                                        },
                                        icon: const Icon(Icons.schedule, size: 18),
                                        label: Text(
                                          'Ver Horarios',
                                          style: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showAddScheduleDialog(clase),
                                        icon: const Icon(Icons.add_circle_outline,
                                            size: 18),
                                        label: Text(
                                          'Agregar',
                                          style: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showEditClassDialog(clase),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: Text(
                                          'Editar',
                                          style: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.sonicSilver,
                                          side: BorderSide(
                                            color: AppColors.sonicSilver.withOpacity(0.5),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showDeleteClassDialog(clase),
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: Text(
                                          'Eliminar',
                                          style: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                            color: AppColors.error,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: FloatingActionButton(
          onPressed: _showCreateClassDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.sonicSilver),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 12,
            color: AppColors.sonicSilver,
          ),
        ),
      ],
    );
  }
}
