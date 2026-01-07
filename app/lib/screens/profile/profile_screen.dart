import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final membership = authProvider.membership;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.white,
                    child: user?.foto != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user!.foto!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nombreCompleto ?? 'Usuario',
                    style: GoogleFonts.catamaran(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Membership Info
            if (membership != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de Membresía',
                          style: GoogleFonts.catamaran(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.richBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Plan',
                          value: membership.planNombre,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Fecha de inicio',
                          value: membership.fechaInicio,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Fecha de vencimiento',
                          value: membership.fechaFin,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Días restantes',
                          value: '${membership.diasRestantes} días',
                          valueColor: membership.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Personal Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Personal',
                        style: GoogleFonts.catamaran(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.richBlack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Email',
                        value: user?.email ?? '',
                      ),
                      if (user?.telefono != null) ...[
                        const Divider(),
                        _InfoRow(
                          label: 'Teléfono',
                          value: user!.telefono!,
                        ),
                      ],
                      if (user?.documento != null) ...[
                        const Divider(),
                        _InfoRow(
                          label: 'Documento',
                          value: user!.documento!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.settings, color: AppColors.primary),
                      title: Text(
                        'Configuración',
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.sonicSilver,
                      ),
                      onTap: () {
                        // TODO: Navegar a configuración
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: AppColors.primary),
                      title: Text(
                        'Ayuda y Soporte',
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.sonicSilver,
                      ),
                      onTap: () {
                        // TODO: Navegar a ayuda
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: AppColors.error),
                      title: Text(
                        'Cerrar Sesión',
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Cerrar Sesión',
                              style: GoogleFonts.catamaran(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            content: Text(
                              '¿Estás seguro de que deseas cerrar sesión?',
                              style: GoogleFonts.rubik(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: Text('Cerrar Sesión'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 14,
            color: AppColors.sonicSilver,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.richBlack,
          ),
        ),
      ],
    );
  }
}

