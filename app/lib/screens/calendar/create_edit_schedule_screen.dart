import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_model.dart';
import '../../models/class_schedule_model.dart';
import '../../utils/snackbar_helper.dart';

class CreateEditScheduleScreen extends StatefulWidget {
  final ClassModel clase;
  final ClassScheduleModel? schedule;

  const CreateEditScheduleScreen({
    super.key,
    required this.clase,
    this.schedule,
  });

  @override
  State<CreateEditScheduleScreen> createState() => _CreateEditScheduleScreenState();
}

class _CreateEditScheduleScreenState extends State<CreateEditScheduleScreen> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  int _selectedDay = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  final List<Map<String, dynamic>> _days = [
    {'id': 1, 'name': 'Lunes'},
    {'id': 2, 'name': 'Martes'},
    {'id': 3, 'name': 'Miércoles'},
    {'id': 4, 'name': 'Jueves'},
    {'id': 5, 'name': 'Viernes'},
    {'id': 6, 'name': 'Sábado'},
    {'id': 7, 'name': 'Domingo'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedDay = widget.schedule!.diaSemana;
      _startTime = _parseTimeString(widget.schedule!.horaInicio);
      _endTime = _parseTimeString(widget.schedule!.horaFin);
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.richBlack,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Ajustar hora fin si es menor que inicio
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    // Validar que hora fin sea mayor que inicio
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      SnackBarHelper.error(
        context,
        'La hora de fin debe ser posterior a la hora de inicio',
        title: 'Horario Inválido',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> result;
      final horaInicio = _formatTimeOfDay(_startTime);
      final horaFin = _formatTimeOfDay(_endTime);

      if (widget.schedule == null) {
        result = await _apiService.createClassSchedule(
          claseId: widget.clase.id,
          diaSemana: _selectedDay,
          horaInicio: horaInicio,
          horaFin: horaFin,
        );
      } else {
        result = await _apiService.updateClassSchedule(
          id: widget.schedule!.id,
          diaSemana: _selectedDay,
          horaInicio: horaInicio,
          horaFin: horaFin,
          activo: widget.schedule!.activo,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result['success'] == true) {
          SnackBarHelper.success(
            context,
            widget.schedule == null
                ? 'Horario agregado exitosamente'
                : 'Horario actualizado exitosamente',
            title: '¡Éxito!',
          );
          Navigator.of(context).pop(true);
        } else {
          SnackBarHelper.error(
            context,
            result['message'] ?? 'Error al guardar el horario',
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        SnackBarHelper.error(
          context,
          'Error de conexión: ${e.toString()}',
          title: 'Error de Red',
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
          widget.schedule == null ? 'Nuevo Horario' : 'Editar Horario',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.richBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
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
                      Icons.schedule,
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
                          widget.clase.nombre,
                          style: GoogleFonts.catamaran(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.richBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configura el día y la hora de la sesión',
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

            // Day Selection
            _buildSectionTitle('Selecciona el Día'),
            const SizedBox(height: 12),
            Container(
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
              child: Column(
                children: _days.map((day) {
                  final isSelected = _selectedDay == day['id'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDay = day['id'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: day['id'] != 7
                            ? Border(
                                bottom: BorderSide(
                                  color: AppColors.lightGray.withOpacity(0.5),
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : AppColors.sonicSilver,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            day['name'],
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColors.richBlack : AppColors.sonicSilver,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Time Selection
            _buildSectionTitle('Horario de la Clase'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerCard(
                    label: 'Hora Inicio',
                    time: _startTime,
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePickerCard(
                    label: 'Hora Fin',
                    time: _endTime,
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSchedule,
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        widget.schedule == null ? 'Agregar Horario' : 'Guardar Cambios',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
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

  Widget _buildTimePickerCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 12,
                color: AppColors.sonicSilver,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeOfDay(time),
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.richBlack,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
