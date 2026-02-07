import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_model.dart';
import '../../models/class_schedule_model.dart';
import '../../utils/snackbar_helper.dart';

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

  Future<void> _navigateToAddSchedule() async {
    final result = await Navigator.pushNamed(
      context,
      '/create_edit_schedule',
      arguments: {
        'clase': widget.clase,
        'schedule': null,
      },
    );

    if (result == true && mounted) {
      _loadSchedules();
    }
  }

  Future<void> _navigateToEditSchedule(ClassScheduleModel schedule) async {
    final result = await Navigator.pushNamed(
      context,
      '/create_edit_schedule',
      arguments: {
        'clase': widget.clase,
        'schedule': schedule,
      },
    );

    if (result == true && mounted) {
      _loadSchedules();
    }
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
        SnackBarHelper.success(
          context,
          'Horario eliminado exitosamente',
          title: '¡Éxito!',
        );
        _loadSchedules();
      } else {
        SnackBarHelper.error(
          context,
          result['message'] ?? 'Error al eliminar el horario',
          title: 'Error',
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
                                    () => _navigateToEditSchedule(schedule),
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
        onPressed: _navigateToAddSchedule,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
