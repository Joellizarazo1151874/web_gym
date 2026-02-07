import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/activity_stats_widget.dart';


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
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(() {
      if (_scrollController.offset > 80 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 80 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loadingNotifications = true;
    });
    try {
      final notifications = await _apiService.getNotifications(soloNoLeidas: true);
      setState(() {
        _notifications = notifications;
        _loadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        _loadingNotifications = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userOk = await authProvider.refreshUserData();
    await _loadNotifications();

    if (!mounted) return;
    SnackBarHelper.show(
      context: context,
      message: userOk ? 'Datos sincronizados' : 'Error al sincronizar',
      type: userOk ? SnackBarType.success : SnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final membership = authProvider.membership;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER & CARD STACK ---
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Extensor rojo oculto (solo visible al estirar hacia abajo)
                    Positioned(
                      top: -400,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 400,
                        color: AppColors.primary,
                      ),
                    ),
                    // Red Header Container (Smaller)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with Status Indicator (Smaller)
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white24,
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.gainsboro,
                                        backgroundImage: user?.foto != null 
                                          ? CachedNetworkImageProvider(user!.foto!) 
                                          : null,
                                        child: user?.foto == null 
                                          ? Text(
                                              user?.nombre?.isNotEmpty == true 
                                                ? user!.nombre![0].toUpperCase() 
                                                : 'U',
                                              style: GoogleFonts.catamaran(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.primary,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.primary, width: 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Greeting text (Spanish)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      'BIENVENIDO DE NUEVO,',
                                      style: GoogleFonts.rubik(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      '${user?.nombre?.split(' ').first ?? 'Usuario'} ${user?.apellido?.split(' ').first ?? ''}!',
                                      style: GoogleFonts.catamaran(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification Button
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                                    ),
                                  ),
                                  if (_notifications.isNotEmpty)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Overlapping Membership Card (Smaller & More Info)
                    Positioned(
                      top: 120,
                      left: 24,
                      right: 24,
                      child: _buildMembershipCard(membership, user?.id),
                    ),
                  ],
                ),
                
                // Spacing for the overlapping card
                const SizedBox(height: 110),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- QUICK ACTIONS ---
                      _buildSectionHeader('Accesos Rápidos'),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _buildQuickAction(
                            context,
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Check-in',
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.pushNamed(context, '/qr'),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            context,
                            icon: Icons.calendar_today_rounded,
                            label: 'Clases',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            context,
                            icon: Icons.smart_toy_rounded,
                            label: 'Entrenador IA',
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.pushNamed(context, '/ai-trainer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // --- ACTIVITY STATS ---
                      ActivityStatsWidget(
                        asistenciasMes: user?.asistenciasMes ?? 0,
                        rachaActual: user?.rachaActual ?? 0,
                      ),
                      const SizedBox(height: 35),

                      // --- NOTIFICATIONS SECTION ---

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('Notificaciones'),
                          if (_notifications.isNotEmpty)
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/notifications'),
                              child: Text(
                                'Ver todas',
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationsList(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.catamaran(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.richBlack.withOpacity(0.8),
      ),
    );
  }

  Widget _buildMembershipCard(dynamic membership, int? userId) {
    // Valores por defecto para cuando no hay membresía (null)
    final bool isActive = membership?.isActive ?? false;
    final bool isExpiring = (membership?.diasRestantes ?? 0) <= 5;
    final String planNombre = membership?.planNombre ?? 'SIN MEMBRESÍA';
    final String fechaInicio = membership?.fechaInicio ?? '--/--/--';
    final String fechaFin = membership?.fechaFin ?? '--/--/--';
    final int diasRestantes = membership?.diasRestantes ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVA' : 'INACTIVA',
                        style: GoogleFonts.rubik(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isActive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive ? planNombre.toUpperCase() : 'SIN MEMBRESÍA',
                      style: GoogleFonts.catamaran(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMemberInfoItem('INICIO', fechaInicio),
              _buildMemberInfoItem('VENCE', fechaFin),
              _buildMemberInfoItem('DÍAS', '$diasRestantes'),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (diasRestantes / 30).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpiring ? const Color(0xFFEF4444) : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildMemberInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.richBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_loadingNotifications) {
      return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
    }

    if (_notifications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, color: AppColors.lightGray, size: 40),
            const SizedBox(height: 12),
            Text(
              'No hay novedades',
              style: GoogleFonts.rubik(color: AppColors.sonicSilver, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: _notifications.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          final isLast = index == _notifications.take(3).length - 1;

          return Column(
            children: [
              ListTile(
                onTap: () async {
                  await _apiService.markNotificationRead(notification.id);
                  _loadNotifications();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
                ),
                title: Text(
                  notification.titulo,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.richBlack,
                  ),
                ),
                subtitle: Text(
                  notification.mensaje,
                  style: GoogleFonts.rubik(fontSize: 13, color: AppColors.sonicSilver),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: AppColors.background, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
