import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<NotificationModel> _notifications = [];
  bool _loadingNotifications = true;

  String _getDynamicGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    // Índice simple para variar mensajes sin usar Random (evita estado extra)
    int index = now.day + now.hour + now.minute;

    if (hour < 12) {
      final mensajesManana = [
        'Buenos días, hoy es un buen día para entrenar.',
        'Buenos días, un pequeño esfuerzo marca la diferencia.',
        'Buenos días, empieza el día moviendo el cuerpo.',
        'Buenos días, constancia antes que intensidad.',
        'Buenos días, hoy puedes acercarte un poco más a tu objetivo.',
      ];
      return mensajesManana[index % mensajesManana.length];
    } else if (hour < 18) {
      final mensajesTarde = [
        'Buenas tardes, mantén el ritmo.',
        'Buenas tardes, una sesión más suma mucho.',
        'Buenas tardes, tómate un momento para ti y entrena.',
        'Buenas tardes, tu cuerpo agradece cada movimiento.',
        'Buenas tardes, sigue construyendo el hábito.',
      ];
      return mensajesTarde[index % mensajesTarde.length];
    } else {
      final mensajesNoche = [
        'Buenas noches, no olvides cuidar tu cuerpo.',
        'Buenas noches, un estiramiento suave también cuenta.',
        'Buenas noches, descansa bien para rendir mejor mañana.',
        'Buenas noches, hoy también fue un avance.',
        'Buenas noches, recargar energía también es parte del entrenamiento.',
      ];
      return mensajesNoche[index % mensajesNoche.length];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loadingNotifications = true;
    });
    final notifications = await _apiService.getNotifications(
      soloNoLeidas: true,
    );
    setState(() {
      _notifications = notifications;
      _loadingNotifications = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final membership = authProvider.membership;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primera fila: Saludo y botón de notificaciones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola,',
                                  style: GoogleFonts.rubik(
                                    fontSize: 15,
                                    color: AppColors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user?.nombreCompleto ?? 'Usuario',
                                  style: GoogleFonts.catamaran(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.white,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDynamicGreeting(),
                                  style: GoogleFonts.rubik(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Botón de notificaciones (estilo badge circular)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(26),
                                  onTap: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/notifications');
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(
                                        0.9,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              if (_notifications.isNotEmpty)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Antes aquí se mostraba el estado de la membresía bajo el nombre.
                      // Ahora toda la información de membresía vive en la tarjeta "Mi Membresía".
                    ],
                  ),
                ),
              ),

              // Membership Card (siempre visible, cambia contenido según estado)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Builder(
                      builder: (context) {
                        final hasMembership = membership != null;
                        final isActive = hasMembership && membership.isActive;
                        final isExpired = hasMembership && !isActive;

                        String statusLabel;
                        Color statusColor;
                        String subtitleText;
                        String daysText;
                        Color daysColor;

                        if (isActive) {
                          statusLabel = 'ACTIVA';
                          statusColor = membership.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.success;
                          subtitleText = membership.planNombre;
                          daysText =
                              '${membership.diasRestantes} días restantes';
                          daysColor = membership.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.primary;
                        } else if (isExpired) {
                          statusLabel = 'INACTIVA';
                          statusColor = AppColors.error;
                          final fechaFin = membership.fechaFin;
                          subtitleText = 'Membresía vencida desde $fechaFin';
                          daysText = '0 días restantes';
                          daysColor = AppColors.sonicSilver;
                        } else {
                          // Nunca ha tenido membresía
                          statusLabel = 'INACTIVA';
                          statusColor = AppColors.error;
                          subtitleText = 'Sin membresía';
                          daysText = 'Adquiere una membresía para comenzar';
                          daysColor = AppColors.sonicSilver;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mi Membresía',
                                  style: GoogleFonts.catamaran(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.richBlack,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.rubik(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              subtitleText,
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                color: AppColors.sonicSilver,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: daysColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    daysText,
                                    style: GoogleFonts.rubik(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: daysColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Accesos Rápidos',
                  style: GoogleFonts.catamaran(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.richBlack,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.qr_code_scanner,
                        title: 'QR Check-in',
                        onTap: () {
                          Navigator.of(context).pushNamed('/qr');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.calendar_today,
                        title: 'Calendario',
                        onTap: () {
                          Navigator.of(context).pushNamed('/calendar');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.smart_toy,
                        title: 'Entrenador IA',
                        onTap: () {
                          Navigator.of(context).pushNamed('/ai-trainer');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.person,
                        title: 'Perfil',
                        onTap: () {
                          Navigator.of(context).pushNamed('/profile');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Notifications
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notificaciones',
                      style: GoogleFonts.catamaran(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.richBlack,
                      ),
                    ),
                    if (_notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Ver todas las notificaciones
                        },
                        child: Text(
                          'Ver todas',
                          style: GoogleFonts.rubik(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingNotifications)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No hay notificaciones nuevas',
                      style: GoogleFonts.rubik(color: AppColors.sonicSilver),
                    ),
                  ),
                )
              else
                ..._notifications
                    .take(3)
                    .map(
                      (notification) => _NotificationItem(
                        notification: notification,
                        onTap: () async {
                          await _apiService.markNotificationRead(
                            notification.id,
                          );
                          _loadNotifications();
                        },
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo con fondo rosa claro e icono rojo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              // Texto negro
              Text(
                title,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.leida
                ? AppColors.white
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.leida
                  ? AppColors.lightGray
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.titulo,
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.richBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.mensaje,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: AppColors.sonicSilver,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.leida)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
