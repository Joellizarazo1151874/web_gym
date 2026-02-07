import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class ActivityStatsWidget extends StatelessWidget {
  final int asistenciasMes;
  final int rachaActual;

  const ActivityStatsWidget({
    super.key,
    required this.asistenciasMes,
    required this.rachaActual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu Actividad',
          style: GoogleFonts.catamaran(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            // Card Asistencias (Mes)
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
                value: asistenciasMes.toString(),
                label: 'Asistencias (Mes)',
              ),
            ),
            const SizedBox(width: 15),
            // Card Racha Actual
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFF7ED),
                value: '$rachaActual días',
                label: 'Racha Actual',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gainsboro.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.catamaran(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.richBlack,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.sonicSilver,
            ),
          ),
        ],
      ),
    );
  }
}
