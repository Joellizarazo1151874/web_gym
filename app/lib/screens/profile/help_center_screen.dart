import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _contactConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _apiService.getContactConfig();
      if (mounted) {
        setState(() {
          _contactConfig = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Funciones para lanzar acciones de contacto
  Future<void> _launchWhatsApp() async {
    final phone = _contactConfig?['telefono_1']?.replaceAll(RegExp(r'[^0-9]'), '') ?? "573209939817";
    final url = Uri.parse("https://wa.me/$phone?text=Hola! Necesito ayuda con la app de FTGym");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall() async {
    final phone = _contactConfig?['telefono_1']?.replaceAll(RegExp(r'[^0-9]'), '') ?? "573209939817";
    final url = Uri.parse("tel:+$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.richBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Centro de Ayuda',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w900,
            color: AppColors.richBlack,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo podemos ayudarte?',
                    style: GoogleFonts.catamaran(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.richBlack,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- CONTACT OPTIONS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: _launchWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.phone_in_talk_outlined,
                          label: 'Llamar',
                          color: AppColors.primary,
                          onTap: _makeCall,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 35),
                  _buildSectionHeader('Preguntas Frecuentes'),
                  const SizedBox(height: 15),
                  
                  _buildFAQItem(
                    context,
                    'Mi código QR no funciona',
                    'Asegúrate de tener el brillo de tu pantalla al máximo. Si el problema persiste, puedes hacer el check-in con tu número de documento en recepción.',
                  ),
                  _buildFAQItem(
                    context,
                    '¿Cómo renuevo mi membresía?',
                    'Puedes renovar directamente en la recepción del gimnasio. El personal verificará tu pago y actualizará tu acceso de inmediato.',
                  ),
                  _buildFAQItem(
                    context,
                    '¿Puedo cambiar mi foto de perfil?',
                    '¡Claro! Ve a tu Perfil y toca el icono de la cámara sobre tu foto actual. Puedes elegir una de tu galería o tomar una nueva.',
                  ),
                  _buildFAQItem(
                    context,
                    '¿Cómo funciona el AI Trainer?',
                    'Es tu entrenador virtual. Analiza tus objetivos para mostrarte rutinas recomendadas. Encuéntralo en el menú principal.',
                  ),
                  _buildFAQItem(
                    context,
                    '¿Tienen redes sociales?',
                    'Sí, búscanos en Instagram como @FTGym para ver tips de entrenamiento, horarios especiales y eventos de la comunidad.',
                  ),

                  const SizedBox(height: 35),
                  _buildSectionHeader('Ubicación y Horarios'),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.location_on_outlined, _contactConfig?['direccion'] ?? 'Dirección no disponible'),
                        const Divider(height: 30),
                        _buildInfoRow(
                          Icons.access_time_rounded, 
                          'Horario: ${_contactConfig?['horario_apertura'] ?? '06:00'} - ${_contactConfig?['horario_cierre'] ?? '22:00'}'
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.calendar_month_outlined, 
                          'Días: ${_contactConfig?['dias_semana'] is List ? (_contactConfig?['dias_semana'] as List).join(', ') : 'Lunes a Sábado'}'
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.richBlack, fontSize: 14),
            ),
          ],
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
        color: AppColors.richBlack,
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.richBlack),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.sonicSilver,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              answer,
              style: GoogleFonts.rubik(fontSize: 13, color: AppColors.sonicSilver, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.rubik(fontSize: 14, color: AppColors.richBlack),
          ),
        ),
      ],
    );
  }
}
