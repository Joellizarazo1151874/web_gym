import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/activity_stats_widget.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ScrollController _scrollController;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  bool _showTitle = false;
  bool _isUploading = false;

  Future<void> _handleProfileImageUpdate(BuildContext context, AuthProvider authProvider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.gallery, authProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.camera, authProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source, AuthProvider authProvider) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // 1. Subir imagen
      final String? imageUrl = await _apiService.uploadPostImage(image.path);

      if (imageUrl != null) {
        // 2. Actualizar perfil con la nueva URL
        final success = await _apiService.updateProfile({'foto': imageUrl});

        if (success && mounted) {
           // 3. Refrescar usuario localmente
           await authProvider.refreshUserData();
           SnackBarHelper.success(context, 'Foto de perfil actualizada');
        } else if (mounted) {
           SnackBarHelper.error(context, 'Error al actualizar el perfil');
        }
      } else if (mounted) {
        SnackBarHelper.error(context, 'Error al subir la imagen');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.error(context, 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 100 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getInitial() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.nombre != null && user!.nombre.trim().isNotEmpty) {
      return user.nombre.trim()[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final membership = authProvider.membership;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
        statusBarBrightness: Brightness.light, // Para iOS
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.richBlack, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Perfil',
            style: GoogleFonts.catamaran(
              fontWeight: FontWeight.w900,
              color: AppColors.richBlack,
              fontSize: 18,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.richBlack),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) {
                if (value == 'config') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                } else if (value == 'password') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'config',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined, size: 20, color: AppColors.richBlack),
                      const SizedBox(width: 12),
                      Text('Editar perfil', style: GoogleFonts.rubik(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'password',
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.richBlack),
                      const SizedBox(width: 12),
                      Text('Cambiar contraseña', style: GoogleFonts.rubik(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),

          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // --- HEADER SECTION ---
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.gainsboro,
                          child: user?.foto != null && user!.foto!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user!.foto!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: Text(
                                        _getInitial(),
                                        style: GoogleFonts.catamaran(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary.withOpacity(0.5),
                                          fontSize: 48,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        _getInitial(),
                                        style: GoogleFonts.catamaran(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          fontSize: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitial(),
                                    style: GoogleFonts.catamaran(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 48,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _handleProfileImageUpdate(context, authProvider),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user?.nombreCompleto ?? 'Usuario',
                  style: GoogleFonts.catamaran(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.richBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.rol?.toUpperCase() ?? 'CLIENTE',
                    style: GoogleFonts.rubik(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- MEMBERSHIP CARD ---
                if (membership != null) ...[
                  _buildMembershipCard(membership),
                  const SizedBox(height: 35),
                ],

                // --- ACTIVITY STATS ---
                ActivityStatsWidget(
                  asistenciasMes: user?.asistenciasMes ?? 0,
                  rachaActual: user?.rachaActual ?? 0,
                ),
                const SizedBox(height: 35),

                // --- INFO SECTIONS ---
                _buildSectionHeader('Información de cuenta'),
                const SizedBox(height: 15),
                _buildModernMenuCard([
                  _MenuItem(
                    icon: Icons.alternate_email_rounded,
                    label: 'Correo electrónico',
                    value: user?.email ?? '',
                  ),
                  if (user?.telefono != null)
                    _MenuItem(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Teléfono móvil',
                      value: user!.telefono!,
                    ),
                  if (user?.documento != null)
                    _MenuItem(
                      icon: Icons.badge_outlined,
                      label: 'Documento de identidad',
                      value: user!.documento!,
                    ),
                ]),
                
                const SizedBox(height: 30),
                _buildSectionHeader('Preferencias y seguridad'),
                const SizedBox(height: 15),
                _buildModernMenuCard([
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Cambiar contraseña',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Editar perfil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                  ),

                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Centro de ayuda',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                      );
                    },
                  ),

                ]),

                const SizedBox(height: 30),
                // --- LOGOUT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    label: Text(
                      'Cerrar sesión',
                      style: GoogleFonts.rubik(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.catamaran(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.lightGray.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildMembershipCard(dynamic membership) {
    final bool isExpiring = membership.diasRestantes <= 5;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpiring 
            ? [const Color(0xFFF87171), const Color(0xFFEF4444)]
            : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isExpiring ? Colors.red : Colors.black).withOpacity(0.3),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAN ACTUAL',
                    style: GoogleFonts.rubik(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    membership.planNombre.toUpperCase(),
                    style: GoogleFonts.catamaran(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMemberInfoItem('INICIO', membership.fechaInicio),
              _buildMemberInfoItem('VENCE', membership.fechaFin),
              _buildMemberInfoItem('DÍAS', '${membership.diasRestantes}'),
            ],
          ),
          const SizedBox(height: 25),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (membership.diasRestantes / 30).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExpiring ? Colors.white : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
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

  Widget _buildModernMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: AppColors.richBlack, size: 22),
                ),
                title: Text(
                  item.label,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.richBlack,
                  ),
                ),
                subtitle: item.value != null ? Text(
                  item.value!,
                  style: GoogleFonts.rubik(fontSize: 13, color: AppColors.sonicSilver),
                ) : null,
                trailing: item.onTap != null 
                  ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.lightGray)
                  : null,
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

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Cerrar sesión?', style: GoogleFonts.catamaran(fontWeight: FontWeight.w900)),
        content: const Text('Tendrás que volver a ingresar tus credenciales para acceder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.rubik(color: AppColors.sonicSilver)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  _MenuItem({required this.icon, required this.label, this.value, this.onTap});
}

