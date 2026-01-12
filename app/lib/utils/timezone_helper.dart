import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

/// Helper para manejar fechas y horas con zona horaria de Colombia
class TimezoneHelper {
  /// Zona horaria de Colombia (Bogotá)
  static final tz.Location bogota = tz.getLocation('America/Bogota');

  /// Obtener la hora actual en Colombia
  static tz.TZDateTime now() {
    return tz.TZDateTime.now(bogota);
  }

  /// Convertir DateTime UTC a hora de Colombia
  static tz.TZDateTime fromUtc(DateTime utcDateTime) {
    return tz.TZDateTime.from(utcDateTime, bogota);
  }

  /// Convertir DateTime local a hora de Colombia
  static tz.TZDateTime fromLocal(DateTime localDateTime) {
    final utc = localDateTime.toUtc();
    return tz.TZDateTime.from(utc, bogota);
  }

  /// Crear fecha/hora específica en zona horaria de Colombia
  static tz.TZDateTime createDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
  ]) {
    return tz.TZDateTime(
      bogota,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  /// Parsear string de fecha ISO 8601 a hora de Colombia
  static tz.TZDateTime parseIso8601(String dateString) {
    final utc = DateTime.parse(dateString).toUtc();
    return tz.TZDateTime.from(utc, bogota);
  }

  /// Formatear fecha/hora en formato legible español
  static String format(tz.TZDateTime dateTime, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    final formatter = DateFormat(pattern, 'es_ES');
    return formatter.format(dateTime);
  }

  /// Formatear solo fecha
  static String formatDate(tz.TZDateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    final formatter = DateFormat(pattern, 'es_ES');
    return formatter.format(dateTime);
  }

  /// Formatear solo hora
  static String formatTime(tz.TZDateTime dateTime, {String pattern = 'HH:mm'}) {
    final formatter = DateFormat(pattern, 'es_ES');
    return formatter.format(dateTime);
  }

  /// Formatear fecha relativa (hoy, ayer, etc.)
  static String formatRelative(tz.TZDateTime dateTime) {
    final now = TimezoneHelper.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Justo ahora';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (days == 1) return 'Ayer';
      return 'Hace $days días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    }
  }

  /// Obtener inicio del día (00:00:00)
  static tz.TZDateTime startOfDay(tz.TZDateTime dateTime) {
    return tz.TZDateTime(
      bogota,
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
  }

  /// Obtener fin del día (23:59:59)
  static tz.TZDateTime endOfDay(tz.TZDateTime dateTime) {
    return tz.TZDateTime(
      bogota,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Verificar si es hoy
  static bool isToday(tz.TZDateTime dateTime) {
    final now = TimezoneHelper.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Verificar si es ayer
  static bool isYesterday(tz.TZDateTime dateTime) {
    final yesterday = TimezoneHelper.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Verificar si es mañana
  static bool isTomorrow(tz.TZDateTime dateTime) {
    final tomorrow = TimezoneHelper.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// Agregar días
  static tz.TZDateTime addDays(tz.TZDateTime dateTime, int days) {
    return dateTime.add(Duration(days: days));
  }

  /// Agregar horas
  static tz.TZDateTime addHours(tz.TZDateTime dateTime, int hours) {
    return dateTime.add(Duration(hours: hours));
  }

  /// Agregar minutos
  static tz.TZDateTime addMinutes(tz.TZDateTime dateTime, int minutes) {
    return dateTime.add(Duration(minutes: minutes));
  }

  /// Calcular días restantes desde hoy
  static int daysUntil(tz.TZDateTime futureDate) {
    final now = startOfDay(TimezoneHelper.now());
    final target = startOfDay(futureDate);
    return target.difference(now).inDays;
  }

  /// Convertir string de fecha del API (formato MySQL) a DateTime de Colombia
  static tz.TZDateTime fromMySqlString(String mysqlDateTime) {
    // Formato MySQL: 2024-01-10 15:30:00
    // Asumir que el servidor ya está en Colombia, así que no convertir timezone
    final parts = mysqlDateTime.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0', '0'];

    return createDateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
      int.parse(timeParts[2]), // second
    );
  }

  /// Convertir a formato MySQL (para enviar al servidor)
  static String toMySqlString(tz.TZDateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}
