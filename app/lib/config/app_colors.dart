import 'package:flutter/material.dart';

/// Colores de la aplicación basados en el landing page
/// Colores configurables acordes al diseño del gimnasio
class AppColors {
  // Color principal - Coquelicot (Rojo/Naranja)
  static const Color primary = Color(0xFFE63946); // hsl(0, 85%, 50%)
  static const Color primaryLight = Color(0xFFF77F7F);
  static const Color primaryDark = Color(0xFFB02A35);
  
  // Colores con opacidad
  static Color primary20 = primary.withOpacity(0.2);
  static Color primary10 = primary.withOpacity(0.1);
  
  // Colores oscuros
  static const Color richBlack = Color(0xFF1A1F2E); // hsl(210, 26%, 11%)
  static const Color richBlackDark = Color(0xFF0A0D14); // hsl(210, 50%, 4%)
  static Color richBlack50 = richBlack.withOpacity(0.5);
  
  // Colores grises
  static const Color silverMetallic = Color(0xFFA8B0B8); // hsl(212, 9%, 67%)
  static const Color sonicSilver = Color(0xFF787878); // hsl(0, 0%, 47%)
  static const Color cadetGray = Color(0xFF8FA0B8); // hsl(214, 15%, 62%)
  static const Color lightGray = Color(0xFFCCCCCC); // hsl(0, 0%, 80%)
  static const Color gainsboro = Color(0xFFE0E0E0); // hsl(0, 0%, 88%)
  
  // Colores básicos
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static Color white20 = white.withOpacity(0.2);
  static Color white10 = white.withOpacity(0.1);
  static Color black10 = black.withOpacity(0.1);
  
  // Colores de estado
  static const Color success = Color(0xFF1AA053);
  static const Color warning = Color(0xFFF16A1B);
  static const Color error = Color(0xFFC03221);
  static const Color info = Color(0xFF079AA2);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, Color(0xFFF8F9FA)],
  );
  
  // Sombras
  static List<BoxShadow> shadow1 = [
    BoxShadow(
      color: black10,
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];
  
  static List<BoxShadow> shadow2 = [
    BoxShadow(
      color: primary20,
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

