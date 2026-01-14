import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_model.dart';
import '../../models/class_schedule_model.dart';

class ClassSchedulesScreen extends StatefulWidget {
  final ClassModel clase;

  const ClassSchedulesScreen({super.key, required this.clase});

  @override
  State<ClassSchedulesScreen> createState() => _ClassSchedulesScreenState();
}

class _ClassSchedulesScreenState extends State<ClassSchedulesScreen> {
  final ApiService _apiService = ApiService();
  List<ClassScheduleModel> _schedules = [];
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
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schedules =
          await _apiService.getClassSchedulesByClassId(widget.clase.id);
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar horarios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddScheduleDialog() async {
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
                  'Clase: ${widget.clase.nombre}',
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
                    DropdownMenuItem(
                        value: 1, child: Text('Lunes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 2, child: Text('Martes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 3,
                        child: Text('Miércoles', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 4, child: Text('Jueves', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 5, child: Text('Viernes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 6, child: Text('Sábado', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 7, child: Text('Domingo', style: GoogleFonts.rubik())),
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
              onPressed: () => Navigator.pop(context),
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).showSnackBar(
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

                // Usar el scaffoldContext guardado antes de mostrar el diálogo
                showDialog(
                  context: scaffoldContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final result = await _apiService.createClassSchedule(
                    claseId: widget.clase.id,
                    diaSemana: selectedDay!,
                    horaInicio: horaInicio,
                    horaFin: horaFin,
                  );

                  if (mounted) {
                    Navigator.pop(scaffoldContext); // Cerrar loading

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
                      _loadSchedules();
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

  Future<void> _showEditScheduleDialog(ClassScheduleModel schedule) async {
    int? selectedDay = schedule.diaSemana;
    final horaInicioController = TextEditingController(text: schedule.horaInicio);
    final horaFinController = TextEditingController(text: schedule.horaFin);

    // Guardar el contexto de la pantalla principal antes de mostrar el diálogo
    final scaffoldContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Editar Horario',
            style: GoogleFonts.catamaran(
              fontWeight: FontWeight.w800,
              color: AppColors.richBlack,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    DropdownMenuItem(
                        value: 1, child: Text('Lunes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 2, child: Text('Martes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 3,
                        child: Text('Miércoles', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 4, child: Text('Jueves', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 5, child: Text('Viernes', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 6, child: Text('Sábado', style: GoogleFonts.rubik())),
                    DropdownMenuItem(
                        value: 7, child: Text('Domingo', style: GoogleFonts.rubik())),
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
              onPressed: () => Navigator.pop(context),
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).showSnackBar(
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

                // Usar el scaffoldContext guardado antes de mostrar el diálogo
                showDialog(
                  context: scaffoldContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final result = await _apiService.updateClassSchedule(
                    id: schedule.id,
                    diaSemana: selectedDay!,
                    horaInicio: horaInicio,
                    horaFin: horaFin,
                    activo: schedule.activo,
                  );

                  if (mounted) {
                    Navigator.pop(scaffoldContext); // Cerrar loading

                    if (result['success'] == true) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Horario actualizado exitosamente',
                            style: GoogleFonts.rubik(),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadSchedules();
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Error al actualizar el horario',
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
                'Guardar',
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

  Future<void> _showDeleteScheduleDialog(ClassScheduleModel schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Horario',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este horario?\n\n${schedule.diaNombre} de ${schedule.horaInicioFormateada} a ${schedule.horaFinFormateada}',
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

    if (confirm == true) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _apiService.deleteClassSchedule(schedule.id);

      Navigator.pop(context); // Cerrar loading

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Horario eliminado exitosamente',
              style: GoogleFonts.rubik(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Error al eliminar el horario',
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Horarios - ${widget.clase.nombre}',
          style: GoogleFonts.catamaran(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.richBlack),
            onPressed: _loadSchedules,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 64,
                            color: AppColors.lightGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay horarios programados',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              color: AppColors.sonicSilver,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar uno',
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
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _schedules[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: schedule.activo
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.lightGray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: schedule.activo
                                    ? AppColors.primary
                                    : AppColors.sonicSilver,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              schedule.diaNombre,
                              style: GoogleFonts.catamaran(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.richBlack,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${schedule.horaInicioFormateada} - ${schedule.horaFinFormateada}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    color: AppColors.sonicSilver,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: schedule.activo
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    schedule.activo ? 'Activo' : 'Inactivo',
                                    style: GoogleFonts.rubik(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: schedule.activo
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert,
                                  color: AppColors.sonicSilver),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit,
                                          size: 20, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text('Editar',
                                          style: GoogleFonts.rubik()),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () => _showEditScheduleDialog(schedule),
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete,
                                          size: 20, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text('Eliminar',
                                          style: GoogleFonts.rubik(
                                              color: AppColors.error)),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () => _showDeleteScheduleDialog(schedule),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
