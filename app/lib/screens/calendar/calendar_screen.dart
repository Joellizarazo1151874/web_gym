import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/class_schedule_model.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/timezone_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  DateTime _focusedDay = TimezoneHelper.now();
  DateTime _selectedDay = TimezoneHelper.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = true;
  final Map<DateTime, List<CalendarEvent>> _events = {};
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _apiService.getNotifications(
      soloNoLeidas: true,
    );
    setState(() {
      _notifications = notifications;
    });
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener solo horarios activos
      print('=== DEBUG: Iniciando carga de horarios ===');
      print('Llamando a getClassSchedules con activo: true');

      final schedules = await _apiService.getClassSchedules();

      // Debug: imprimir información de los horarios recibidos
      print('=== DEBUG: Horarios recibidos ===');
      print('Total de horarios: ${schedules.length}');

      if (schedules.isEmpty) {
        print('⚠️ ADVERTENCIA: No se recibieron horarios de la API');
        print('Posibles causas:');
        print('  1. No hay horarios activos en la base de datos');
        print('  2. Error de autenticación');
        print('  3. Error en la consulta SQL');
        print('  4. Problema de conexión con la API');
      } else {
        for (final schedule in schedules) {
          print('Horario ID: ${schedule.id}');
          print('  Clase: ${schedule.claseNombre}');
          print(
            '  Día de semana: ${schedule.diaSemana} (${schedule.diaNombre})',
          );
          print(
            '  Hora inicio: ${schedule.horaInicio} -> ${schedule.horaInicioFormateada}',
          );
          print(
            '  Hora fin: ${schedule.horaFin} -> ${schedule.horaFinFormateada}',
          );
          print('  Activo: ${schedule.activo}');
          print('---');
        }
      }
      print('================================');

      // Cargar eventos para los próximos 7 días desde hoy
      _loadEventsForNext7Days(schedules);

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error al cargar horarios: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadEventsForNext7Days([List<ClassScheduleModel>? schedules]) {
    // Limpiar eventos anteriores
    _events.clear();

    // Si no se proporcionan schedules, no hacer nada (se cargarán en _loadSchedules)
    if (schedules == null || schedules.isEmpty) {
      print('DEBUG: No hay horarios para procesar');
      return;
    }

    // Obtener el día actual (solo fecha, sin hora) - Zona horaria de Colombia
    final today = TimezoneHelper.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final todayWeekday = today.weekday;

    print('=== DEBUG: Generando eventos ===');
    print('Fecha actual: $startDate');
    print(
      'Día de la semana actual: $todayWeekday (${_getDayName(todayWeekday)})',
    );

    // Calcular la fecha de fin (7 días desde hoy, incluyendo hoy)
    final endDate = startDate.add(const Duration(days: 7));
    print('Rango: $startDate hasta $endDate');

    int eventosCreados = 0;

    for (final schedule in schedules) {
      print(
        'Procesando horario: ${schedule.claseNombre} - Día: ${schedule.diaSemana} (${schedule.diaNombre})',
      );

      // Buscar la próxima ocurrencia de este día de la semana dentro de los próximos 7 días
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate)) {
        // Debug: mostrar cada día que se está verificando
        final currentWeekday = currentDate.weekday;
        final scheduleWeekday = schedule.diaSemana;

        // Si el día de la semana coincide con el horario
        if (currentWeekday == scheduleWeekday) {
          final dateKey = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          );

          print(
            '  → Coincidencia encontrada! Día actual: $currentWeekday (${_getDayName(currentWeekday)}), Horario: $scheduleWeekday (${schedule.diaNombre})',
          );
          print('  → Fecha del evento: ${dateKey.toString().substring(0, 10)}');

          if (!_events.containsKey(dateKey)) {
            _events[dateKey] = [];
            print('  → Nueva lista de eventos creada para esta fecha');
          }

          // Verificar si el evento ya existe para evitar duplicados
          final exists = _events[dateKey]!.any(
            (e) =>
                e.schedule?.id == schedule.id &&
                e.time == schedule.horaInicioFormateada,
          );

          if (!exists) {
            _events[dateKey]!.add(
              CalendarEvent(
                title: schedule.claseNombre,
                time: schedule.horaInicioFormateada,
                endTime: schedule.horaFinFormateada,
                type: 'class',
                schedule: schedule,
              ),
            );
            eventosCreados++;
            print(
              '  ✓ Evento creado para ${dateKey.toString().substring(0, 10)} - ${schedule.horaInicioFormateada}',
            );
            print(
              '  ✓ Total eventos en esta fecha: ${_events[dateKey]!.length}',
            );
          } else {
            print('  ✗ Evento duplicado, omitido');
          }
        } else {
          // Debug: mostrar cuando no coincide (solo los primeros días para no saturar)
          if (currentDate.difference(startDate).inDays < 3) {
            print(
              '  - Día ${currentDate.toString().substring(0, 10)}: weekday=$currentWeekday (${_getDayName(currentWeekday)}), no coincide con horario (día $scheduleWeekday)',
            );
          }
        }

        // Avanzar al siguiente día
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    print('Total de eventos creados: $eventosCreados');
    print('Total de días con eventos: ${_events.length}');
    print('Resumen de eventos por fecha:');
    for (final entry in _events.entries) {
      final fecha = entry.key.toString().substring(0, 10);
      final weekday = entry.key.weekday;
      print(
        '  $fecha (${_getDayName(weekday)}): ${entry.value.length} evento(s)',
      );
      for (final event in entry.value) {
        print('    - ${event.title} a las ${event.time}');
      }
    }
    print('================================');
    print('DEBUG: Verificando que los eventos estén accesibles...');
    final todayCheck = TimezoneHelper.now();
    final todayKey = DateTime(
      todayCheck.year,
      todayCheck.month,
      todayCheck.day,
    );
    print('DEBUG: Fecha de hoy: ${todayKey.toString().substring(0, 10)}');
    print('DEBUG: Eventos para hoy: ${_getEventsForDay(todayKey).length}');

    if (mounted) {
      setState(() {});
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Desconocido';
    }
  }

  void _reloadEventsIfNeeded() async {
    // Si el día enfocado está dentro de los próximos 7 días, recargar eventos
    final today = TimezoneHelper.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final focusedDate = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
    final daysDifference = focusedDate.difference(todayDate).inDays;

    // Si el día enfocado está dentro del rango de los próximos 7 días, recargar
    if (daysDifference >= 0 && daysDifference <= 7) {
      try {
        final schedules = await _apiService.getClassSchedules();
        _loadEventsForNext7Days(schedules);
      } catch (e) {
        print('Error al recargar eventos: $e');
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);

    // Debug detallado
    print(
      'DEBUG _getEventsForDay: Consultando día ${dateKey.toString().substring(0, 10)}',
    );
    print(
      'DEBUG _getEventsForDay: Total de fechas en _events: ${_events.length}',
    );

    // Buscar la clave exacta
    List<CalendarEvent>? events;
    for (final entry in _events.entries) {
      if (isSameDay(entry.key, dateKey)) {
        events = entry.value;
        print(
          'DEBUG _getEventsForDay: ✓ Encontrada coincidencia para ${dateKey.toString().substring(0, 10)}',
        );
        print('DEBUG _getEventsForDay: Eventos encontrados: ${events.length}');
        break;
      }
    }

    events ??= [];

    // Debug cuando se consulta un día específico
    if (events.isNotEmpty) {
      print(
        'DEBUG _getEventsForDay: ${dateKey.toString().substring(0, 10)} tiene ${events.length} evento(s)',
      );
      for (final event in events) {
        print('  - ${event.title} a las ${event.time}');
      }
    } else {
      print(
        'DEBUG _getEventsForDay: ✗ No hay eventos para ${dateKey.toString().substring(0, 10)}',
      );
      // Mostrar todas las fechas disponibles para debugging
      if (_events.isNotEmpty) {
        print('DEBUG _getEventsForDay: Fechas disponibles en _events:');
        for (final entry in _events.entries) {
          print(
            '  - ${entry.key.toString().substring(0, 10)}: ${entry.value.length} evento(s)',
          );
        }
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final events = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar Card
                  Container(
                    margin: const EdgeInsets.all(16),
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
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: 'es_ES',
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: GoogleFonts.rubik(
                          fontSize: 14,
                          color: AppColors.richBlack,
                        ),
                        weekendTextStyle: GoogleFonts.rubik(
                          fontSize: 14,
                          color: AppColors.richBlack,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 6,
                        markerMargin: const EdgeInsets.only(bottom: 4),
                        outsideDaysVisible: false,
                        tablePadding: const EdgeInsets.all(8),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: GoogleFonts.catamaran(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.richBlack,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.richBlack,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.richBlack,
                        ),
                        formatButtonShowsNext: false,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sonicSilver,
                        ),
                        weekendStyle: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sonicSilver,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                        _reloadEventsIfNeeded();
                      },
                    ),
                  ),

                  // Events Section
                  Container(
                    color: AppColors.background,
                    child: events.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: AppColors.lightGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay eventos para este día',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    color: AppColors.sonicSilver,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with date and count
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatSelectedDate(_selectedDay),
                                      style: GoogleFonts.catamaran(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.richBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${events.length} ${events.length == 1 ? 'actividad programada' : 'actividades programadas'}',
                                      style: GoogleFonts.rubik(
                                        fontSize: 14,
                                        color: AppColors.sonicSilver,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Events List with Timeline
                              ...events.asMap().entries.map((entry) {
                                final index = entry.key;
                                final event = entry.value;
                                final isLast = index == events.length - 1;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: _buildEventCard(event, isLast),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar acción del FAB
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, user) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/profile');
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: user?.foto != null
                ? ClipOval(
                    child: Image.network(
                      user!.foto!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      user?.nombre?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.rubik(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ),
      ),
      title: Text(
        'Calendario',
        style: GoogleFonts.catamaran(
          fontWeight: FontWeight.w800,
          color: AppColors.richBlack,
        ),
      ),
      centerTitle: true,
      actions: [
        // Notifications Icon
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.richBlack,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
            ),
            if (_notifications.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        // Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.richBlack),
          onPressed: _loadSchedules,
          tooltip: 'Actualizar calendario',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent event, bool isLast) {
    // Determinar color del icono según el tipo de clase
    Color iconColor = AppColors.primary;
    IconData iconData = Icons.fitness_center;

    // Mapear tipos de clase a iconos y colores
    final className = event.title.toLowerCase();
    if (className.contains('yoga')) {
      iconColor = const Color(0xFFFF9800); // Naranja
      iconData = Icons.self_improvement;
    } else if (className.contains('cardio') || className.contains('hiit')) {
      iconColor = const Color(0xFF2196F3); // Azul
      iconData = Icons.favorite;
    } else if (className.contains('crossfit') ||
        className.contains('funcional')) {
      iconColor = AppColors.primary; // Rojo
      iconData = Icons.bolt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: AppColors.lightGray,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Event Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Tag (por ahora siempre "Programado")
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Programado',
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Class Name
                  Text(
                    event.title,
                    style: GoogleFonts.catamaran(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.richBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.sonicSilver,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${event.time} - ${event.endTime ?? ""}',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: AppColors.sonicSilver,
                        ),
                      ),
                    ],
                  ),
                  if (event.schedule?.instructorCompleto != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.sonicSilver,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Instructor: ${event.schedule!.instructorCompleto}',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: AppColors.sonicSilver,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final weekday = _getDayName(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, ${date.day} de $month';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Enero';
      case 2:
        return 'Febrero';
      case 3:
        return 'Marzo';
      case 4:
        return 'Abril';
      case 5:
        return 'Mayo';
      case 6:
        return 'Junio';
      case 7:
        return 'Julio';
      case 8:
        return 'Agosto';
      case 9:
        return 'Septiembre';
      case 10:
        return 'Octubre';
      case 11:
        return 'Noviembre';
      case 12:
        return 'Diciembre';
      default:
        return '';
    }
  }
}

class CalendarEvent {
  final String title;
  final String time;
  final String? endTime;
  final String type;
  final ClassScheduleModel? schedule;

  CalendarEvent({
    required this.title,
    required this.time,
    this.endTime,
    required this.type,
    this.schedule,
  });
}
