import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../models/friend_request_model.dart';
import '../../services/api_service.dart';
import 'chat_conversation_screen.dart';
import '../../models/chat_model.dart';
import '../../utils/snackbar_helper.dart';

class FriendRequestsScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const FriendRequestsScreen({super.key, this.onChanged});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final ApiService _apiService = ApiService();
  List<FriendRequestModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final list = await _apiService.getFriendRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  Future<void> _respond(
    FriendRequestModel req,
    String accion,
  ) async {
    final resp = await _apiService.respondFriendRequest(
      solicitudId: req.id,
      accion: accion,
    );
    if (!mounted) return;

    if (resp['success'] == true) {
      setState(() {
        _requests.removeWhere((r) => r.id == req.id);
      });
      widget.onChanged?.call();

      if (accion == 'aceptar' && resp['chat'] != null) {
        final c = resp['chat'];
        final chat = ChatModel(
          id: c['id'] as int,
          nombre: c['nombre']?.toString() ?? 'Chat privado',
          esGrupal: false,
          creadoEn: c['creado_en']?.toString() ?? '',
          ultimoMensaje: null,
          ultimoMensajeEn: null,
          ultimoRemitente: null,
          unreadCount: 0,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(chat: chat),
          ),
        );
      }
    }

    SnackBarHelper.show(
      context: context,
      message: resp['message']?.toString() ??
          (resp['success'] == true
              ? 'Operación realizada'
              : 'Error en la operación'),
      type: resp['success'] == true ? SnackBarType.success : SnackBarType.error,
      title: resp['success'] == true ? '¡Éxito!' : 'Error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Solicitudes recibidas',
          style: GoogleFonts.catamaran(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'No tienes solicitudes pendientes.',
                    style: GoogleFonts.rubik(color: AppColors.sonicSilver),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Fila superior con avatar e información
                              Row(
                                children: [
                                  // Avatar más grande
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withOpacity(0.8),
                                          AppColors.primary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        req.nombreCompleto.isNotEmpty
                                            ? req.nombreCompleto[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.catamaran(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Información del usuario
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.nombreCompleto,
                                          style: GoogleFonts.rubik(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.richBlack,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          req.email,
                                          style: GoogleFonts.rubik(
                                            fontSize: 13,
                                            color: AppColors.sonicSilver,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Mensaje descriptivo
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Quiere iniciar un chat contigo',
                                        style: GoogleFonts.rubik(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respond(req, 'rechazar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: Colors.red.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Rechazar',
                                            style: GoogleFonts.rubik(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(req, 'aceptar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Aceptar',
                                            style: GoogleFonts.rubik(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

