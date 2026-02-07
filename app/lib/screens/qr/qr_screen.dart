import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final qrData = user?.documento ?? 'NO_DATA';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Acceso QR',
            style: GoogleFonts.catamaran(
              fontWeight: FontWeight.w900,
              color: AppColors.richBlack,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // --- USER INFO CARD ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.gainsboro,
                          backgroundImage: user?.foto != null 
                            ? CachedNetworkImageProvider(user!.foto!) 
                            : null,
                          child: user?.foto == null 
                            ? Text(
                                user?.nombre?.isNotEmpty == true ? user!.nombre![0].toUpperCase() : 'U',
                                style: GoogleFonts.catamaran(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  fontSize: 20,
                                ),
                              ) 
                            : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nombreCompleto ?? 'Usuario',
                              style: GoogleFonts.catamaran(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.richBlack,
                              ),
                            ),
                            Text(
                              authProvider.membership?.isActive == true 
                                ? 'Membresía Activa' 
                                : 'Membresía Vencida',
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: authProvider.membership?.isActive == true 
                                  ? const Color(0xFF22C55E) 
                                  : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- QR CODE CONTAINER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CÓDIGO DE ENTRADA',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sonicSilver,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gainsboro.withOpacity(0.5), width: 1),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.richBlack,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.richBlack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Escanea en recepción',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.richBlack,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                
                // --- INSTRUCTIONS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Presenta este código frente al lector para registrar tu ingreso automáticamente.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.sonicSilver,
                      height: 1.5,
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
}

