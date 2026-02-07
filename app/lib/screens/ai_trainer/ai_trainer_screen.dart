import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'plan_detail_screen.dart';


class AITrainerScreen extends StatefulWidget {

  const AITrainerScreen({super.key});

  @override
  State<AITrainerScreen> createState() => _AITrainerScreenState();
}

class _AITrainerScreenState extends State<AITrainerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, String>> _history = [];
  String _currentAIResponse = "";
  bool _isTyping = false;

  // Variables para el Plan Activo
  String? _planTitle;
  List<dynamic> _exercises = [];
  bool _isLoadingPlan = true;

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }


  Future<void> _loadActivePlan() async {
    try {
      final response = await _apiService.getActivePlan();
      setState(() {
        if (response['success'] == true) {
          _planTitle = response['titulo'];
          _exercises = response['ejercicios'] ?? [];
        }
        
        // Generar saludo dinámico
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        final nombre = user?.nombre ?? 'Atleta';
        final now = DateTime.now();
        // Lógica simple para evitar saludos repetitivos: varía según si hay plan o no
        if (_planTitle != null && _exercises.isNotEmpty) {
           _currentAIResponse = "¡Hola $nombre! Veo que hoy tenemos '$_planTitle'. ¿Listo para darle duro o necesitas algún ajuste antes de empezar?";
        } else {
           // Saludos variados aleatorios
           final saludos = [
             "¡Qué tal, $nombre! Hoy es un gran día para entrenar. ¿Qué músculo quieres trabajar?",
             "Hola $nombre. Tu cuerpo puede más de lo que crees. ¿Vamos a por esa rutina de hoy?",
             "¡Buenas, $nombre! Estoy listo para organizar tu entrenamiento. ¿Por dónde empezamos hoy?"
           ];
           _currentAIResponse = saludos[now.second % saludos.length];
        }
        _history.add({"role": "assistant", "content": _currentAIResponse});
        
        _isLoadingPlan = false;
      });

    } catch (e) {
      setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _sendMessage({String? messageOverride}) async {
    final text = messageOverride ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (messageOverride == null) _messageController.clear();
      _isTyping = true;
    });

    try {
      final response = await _apiService.getAIResponse(text, historial: _history);
      
      setState(() {
        _isTyping = false;
        if (response['success'] == true) {
          _currentAIResponse = response['respuesta'];
          
          _history.add({"role": "user", "content": text});
          _history.add({"role": "assistant", "content": _currentAIResponse});

          if (_history.length > 30) {
            _history.removeRange(0, _history.length - 30);
          }

          // Si la IA generó un nuevo plan, actualizar la lista
          if (response['has_new_plan'] == true && response['plan'] != null) {
            _planTitle = response['plan']['titulo'];
            _exercises = response['plan']['ejercicios'] ?? [];
          }
        } else {
          _currentAIResponse = "Lo siento, tuve un problema al procesar tu mensaje. ¿Podrías intentar de nuevo?";
        }
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _currentAIResponse = "Parece que hay un error de conexión. Revisa tu internet e intenta de nuevo.";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    final asistenciasMes = user?.asistenciasMes ?? 0;
    final rachaActual = user?.rachaActual ?? 0;
    final consistencia = (asistenciasMes / 20 * 100).clamp(0, 100).toInt();

    final isMembershipActive = authProvider.membership?.isActive ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: !isMembershipActive 
             ? _buildLockedState()
             : SingleChildScrollView(

            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // --- AI RESPONSE SECTION (IMAGE STYLE) ---
                _buildDynamicAIResponse(user?.nombre ?? 'Atleta'),
                
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.only(top: 0, left: 10, bottom: 15),
                    child: Text(
                      'El Entrenador está analizando...',
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),

                // --- INTERACTION BAR ---
                _buildInteractionBar(),
                const SizedBox(height: 20),

                // --- ACTION BUTTONS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.auto_awesome_rounded,
                        label: (_planTitle != null && _exercises.isNotEmpty) 
                            ? 'Generar variante de rutina' 
                            : 'Generar plan para hoy',
                        onTap: () {
                           if (_planTitle != null && _exercises.isNotEmpty) {
                             _sendMessage(messageOverride: "Genera una rutina nueva y diferente pero manteniendo el enfoque en '$_planTitle'. Cambia los ejercicios.");
                           } else {
                             _sendMessage(messageOverride: "Hola, genera mi rutina para el día de hoy con sus respectivos videos por favor.");
                           }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),


                // --- STATS GRID ---
                _buildSectionHeader('Tu Resumen Visual', null),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'CONSISTENCIA',
                        value: '$consistencia%',
                        subtitle: 'Este mes',
                        icon: Icons.show_chart_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        label: 'RACHA',
                        value: '$rachaActual días',
                        subtitle: 'Fuego activo 🔥',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                // --- ACTIVE PLAN SECTION ---
                _buildSectionHeader(
                  _planTitle ?? 'Tu Plan Activo', 
                  () {
                    if (_exercises.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlanDetailScreen(
                            title: _planTitle ?? 'Tu Rutina',
                            exercises: _exercises,
                          ),
                        ),
                      );
                    }
                  }
                ),
                const SizedBox(height: 15),


                if (_exercises.isEmpty)
                  _buildEmptyPlanState()
                else
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return _buildEjercicioCard(
                          nombre: ex['n'] ?? 'Ejercicio',
                          descripcion: ex['d'] ?? '',
                          videoUrl: ex['v'] ?? '',
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 35),

                // --- RECOMMENDED SECTION ---
                if (_exercises.isNotEmpty) ...[
                  _buildSectionHeader('Recomendado para hoy', null),
                  const SizedBox(height: 15),
                  _buildRecommendedItem(
                    title: 'Calentamiento Articular',
                    subtitle: '5 minutos antes de iniciar',
                    imageUrl: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=200&auto=format&fit=crop',
                    videoUrl: 'https://www.youtube.com/watch?v=aclHkVaku9U',
                  ),
                  const SizedBox(height: 40),
                ],

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAIResponse(String userName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Futuristic Orb (Same as image layout)
          _buildAIOrb(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrenador Inteligente',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sonicSilver,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.richBlack,
                      height: 1.4,
                    ),
                    children: _buildRichTextParts(_currentAIResponse),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildRichTextParts(String text) {
    // Basic formatting to highlight key fitness terms as in the image
    List<TextSpan> spans = [];
    spans.add(const TextSpan(text: '"'));
    
    // Simplistic highlight logic for demo (can be improved with AI response tags)
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      bool isHighlight = _shouldHighlight(word);
      
      spans.add(TextSpan(
        text: word + (i == words.length - 1 ? "" : " "),
        style: TextStyle(
          color: isHighlight ? AppColors.primary : AppColors.richBlack,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
        ),
      ));
    }
    
    spans.add(const TextSpan(text: '"'));
    return spans;
  }

  bool _shouldHighlight(String word) {
    final highlights = ['recuperación', 'activa', 'intensidad', 'progreso', 'técnica', 'fuerza', 'dieta', 'meta'];
    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    return highlights.contains(cleanWord);
  }

  Widget _buildAIOrb() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Holographic-like circles
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
          ),
          // IA Badge
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'IA',
                style: GoogleFonts.rubik(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary.withOpacity(0.5), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.rubik(color: AppColors.richBlack, fontSize: 14),
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Escribe tu duda aquí...',
                hintStyle: GoogleFonts.rubik(color: AppColors.sonicSilver.withOpacity(0.6), fontSize: 14),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gainsboro.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.rubik(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sonicSilver,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.catamaran(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.richBlack,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.rubik(
              fontSize: 11,
              color: AppColors.sonicSilver,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.catamaran(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.richBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'Ver todo',
              style: GoogleFonts.rubik(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPlanState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gainsboro.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: 40, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 15),
          Text(
            'Aún no tienes una rutina para hoy',
            style: GoogleFonts.catamaran(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.richBlack),
          ),
          const SizedBox(height: 5),
          Text(
            'Presiona "Generar plan" para que la IA diseñe tu entrenamiento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(fontSize: 13, color: AppColors.sonicSilver),
          ),
        ],
      ),
    );
  }

  Widget _buildEjercicioCard({required String nombre, required String descripcion, required String videoUrl}) {

    // Generar miniatura de youtube O imagen genérica si no hay video
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    final hasVideo = videoUrl.isNotEmpty && videoId != null;
    
    final thumbnailUrl = hasVideo 
        ? 'https://img.youtube.com/vi/$videoId/0.jpg' 
        : 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=500&auto=format&fit=crop';

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gainsboro.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (hasVideo) {
                          _showVideoDialog(videoUrl);
                        } else {
                          _launchYoutubeSearch(nombre);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasVideo ? AppColors.primary : Colors.orange, 
                          shape: BoxShape.circle
                        ),
                        child: Icon(
                          hasVideo ? Icons.play_arrow_rounded : Icons.search_rounded, 
                          color: Colors.white, 
                          size: 30
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombre,
                    style: GoogleFonts.catamaran(
                      fontSize: 15, 
                      fontWeight: FontWeight.w800, 
                      color: AppColors.richBlack,
                      height: 1.1,
                    ),
                    maxLines: 2, 
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      descripcion,
                      style: GoogleFonts.rubik(
                        fontSize: 11, 
                        color: AppColors.sonicSilver,
                        height: 1.3,
                      ),
                      maxLines: 4, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _launchYoutubeSearch(String query) async {
    final url = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('No se pudo abrir $url');
      }
    } catch (e) {
      print('Error al lanzar URL: $e');
    }
  }

  void _showVideoDialog(String url) {

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
          ),
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }

  Widget _buildRecommendedItem({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String videoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gainsboro.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: imageUrl, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.catamaran(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.richBlack)),
                Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.sonicSilver)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showVideoDialog(videoUrl),
            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gainsboro.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.richBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedState() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Acceso Exclusivo',
              style: GoogleFonts.catamaran(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.richBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'El Entrenador IA está reservado para miembros activos. Activa tu membresía para disfrutar de planes personalizados.',
              style: GoogleFonts.rubik(
                fontSize: 15,
                color: AppColors.sonicSilver,
                height: 1.5
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



