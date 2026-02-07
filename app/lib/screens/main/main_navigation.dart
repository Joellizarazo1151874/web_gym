import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../qr/qr_screen.dart';
import '../ai_trainer/ai_trainer_screen.dart';
import '../social/social_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const QRScreen(),
    const AITrainerScreen(),
    const SocialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          // SafeArea ya respeta el área del sistema; aquí solo un margen visual ligero
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Barra redondeada con sombra
                Positioned.fill(
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home,
                          label: 'Inicio',
                          isSelected: _currentIndex == 0,
                          onTap: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                          },
                        ),
                        _NavItem(
                          icon: Icons.calendar_today,
                          label: 'Clases',
                          isSelected: _currentIndex == 1,
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                        ),
                        const SizedBox(
                          width: 56,
                        ), // espacio bajo el botón central
                        _NavItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Progreso',
                          isSelected: _currentIndex == 3,
                          onTap: () {
                            setState(() {
                              _currentIndex = 3;
                            });
                          },
                        ),

                        _NavItem(
                          icon: Icons.forum,
                          label: 'Social',
                          isSelected: _currentIndex == 4,
                          onTap: () {
                            setState(() {
                              _currentIndex = 4;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón flotante central para escaneo QR
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.sonicSilver;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
