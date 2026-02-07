import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/app_colors.dart';

class PlanDetailScreen extends StatelessWidget {
  final String title;
  final List<dynamic> exercises;

  const PlanDetailScreen({super.key, required this.title, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.catamaran(color: AppColors.richBlack, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.richBlack),
      ),
      body: exercises.isEmpty
          ? Center(child: Text("No hay ejercicios en este plan", style: GoogleFonts.rubik(color: AppColors.sonicSilver)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: exercises.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final ex = exercises[index];
                return _buildExerciseRow(context, index + 1, ex);
              },
            ),
    );
  }

  Widget _buildExerciseRow(BuildContext context, int index, dynamic exercise) {
    final videoUrl = exercise['v'] ?? '';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    final thumbnailUrl = videoId != null 
        ? 'https://img.youtube.com/vi/$videoId/0.jpg' 
        : 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=500&auto=format&fit=crop';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Numero y Nombre
          Row(
            children: [
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Text('$index', style: GoogleFonts.catamaran(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise['n'] ?? 'Ejercicio',
                  style: GoogleFonts.catamaran(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.richBlack),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Video y Descripcion
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail
              GestureDetector(
                onTap: () => _showVideoDialog(context, videoUrl),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 120, height: 80, fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              
              // Descripcion detallada
              Expanded(
                child: Text(
                  exercise['d'] ?? '',
                  style: GoogleFonts.rubik(fontSize: 13, color: AppColors.sonicSilver, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String url) {
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
}
