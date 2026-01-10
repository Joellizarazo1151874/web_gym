import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../models/chat_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatConversationScreen({super.key, required this.chat});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessageModel> _mensajes = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _currentOffset = 0;
  final int _limite = 15;
  bool _showEmojiPicker = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Detectar cuando el usuario scrollea hacia arriba (inicio de la lista)
    if (_scrollController.position.pixels <= 100 &&
        !_loadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    print('📥 Cargando mensajes iniciales del chat ${widget.chat.id}...');
    setState(() {
      _loading = true;
      _currentOffset = 0;
    });
    final result = await _apiService.getChatMessages(
      widget.chat.id,
      limite: _limite,
      offset: _currentOffset,
    );
    final List<ChatMessageModel> mensajes =
        result['mensajes'] as List<ChatMessageModel>;
    final bool hayMas = result['hayMas'] as bool;
    print('📥 Mensajes cargados: ${mensajes.length}, Hay más: $hayMas');
    setState(() {
      _mensajes = mensajes;
      _hasMore = hayMas;
      _currentOffset = mensajes.length;
      _loading = false;
    });
    _scrollToBottom(instant: true);
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || !_hasMore) return;

    print('📥 Cargando más mensajes del chat ${widget.chat.id}...');
    setState(() {
      _loadingMore = true;
    });

    // Guardar la posición actual del scroll antes de cargar más mensajes
    final double currentScrollPosition = _scrollController.position.pixels;
    final double currentMaxScrollExtent =
        _scrollController.position.maxScrollExtent;

    final result = await _apiService.getChatMessages(
      widget.chat.id,
      limite: _limite,
      offset: _currentOffset,
    );
    final List<ChatMessageModel> nuevosMensajes =
        result['mensajes'] as List<ChatMessageModel>;
    final bool hayMas = result['hayMas'] as bool;
    print(
      '📥 Mensajes adicionales cargados: ${nuevosMensajes.length}, Hay más: $hayMas',
    );

    setState(() {
      // Agregar nuevos mensajes al inicio de la lista (son más antiguos)
      _mensajes.insertAll(0, nuevosMensajes);
      _hasMore = hayMas;
      _currentOffset += nuevosMensajes.length;
      _loadingMore = false;
    });

    // Ajustar el scroll para mantener la posición relativa del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double newMaxScrollExtent =
            _scrollController.position.maxScrollExtent;
        final double scrollDelta = newMaxScrollExtent - currentMaxScrollExtent;
        _scrollController.jumpTo(currentScrollPosition + scrollDelta);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    print('📤 Enviando mensaje: $text');
    _controller.clear();
    final imageToSend = _selectedImage;
    setState(() {
      _selectedImage = null;
      _showEmojiPicker = false;
    });

    String? imageUrl;
    if (imageToSend != null && mounted) {
      // Mostrar indicador de progreso sutil
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.richBlack.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enviando...',
                  style: GoogleFonts.rubik(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      imageUrl = await _apiService.uploadChatImage(imageToSend.path);
      
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      
      if (imageUrl == null && mounted) {
        // Error sutil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('No se pudo enviar la imagen', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }
    
    final sent = await _apiService.sendChatMessage(
      chatId: widget.chat.id,
      mensaje: text.isEmpty && imageUrl != null ? '📷 Foto' : text,
      imagenUrl: imageUrl,
    );
    
    if (sent != null && mounted) {
      print('✅ Mensaje recibido del servidor, agregando a la lista');
      setState(() {
        _mensajes.add(sent);
      });
      _scrollToBottom();
    } else {
      print('❌ No se recibió mensaje del servidor');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('No se pudo enviar', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _showMessageOptions(
      BuildContext context, ChatMessageModel msg, int index) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.imagenUrl == null || msg.imagenUrl!.isEmpty)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar mensaje'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editMessage(context, msg, index);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Eliminar mensaje',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deleteMessage(context, msg, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editMessage(
      BuildContext context, ChatMessageModel msg, int index) async {
    final TextEditingController editController =
        TextEditingController(text: msg.mensaje);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe el nuevo mensaje',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      final nuevoMensaje = editController.text.trim();
      if (nuevoMensaje.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Escribe algo', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final editado = await _apiService.editChatMessage(
        mensajeId: msg.id,
        mensaje: nuevoMensaje,
      );

      if (editado != null && mounted) {
        setState(() {
          _mensajes[index] = editado;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Editado', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('No se pudo editar', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(
      BuildContext context, ChatMessageModel msg, int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final eliminado = await _apiService.deleteChatMessage(msg.id);

      if (eliminado && mounted) {
        setState(() {
          _mensajes.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Eliminado', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('No se pudo eliminar', style: GoogleFonts.rubik(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_scrollController.hasClients) {
        if (instant) {
          // Scroll instantáneo (para carga inicial)
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          
          // Segundo intento después de que las imágenes carguen
          await Future.delayed(const Duration(milliseconds: 300));
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        } else {
          // Scroll animado (para nuevos mensajes)
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  String _formatTime(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                widget.chat.nombre.isNotEmpty 
                    ? widget.chat.nombre[0].toUpperCase() 
                    : '?',
                style: GoogleFonts.catamaran(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.chat.nombre,
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mensajes
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.sonicSilver.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay mensajes aún',
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                color: AppColors.sonicSilver,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sé el primero en escribir',
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                color: AppColors.sonicSilver.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: _mensajes.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Mostrar indicador de carga al inicio si hay más mensajes
                          if (index == 0 && _hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        'Desliza hacia arriba para cargar más',
                                        style: GoogleFonts.rubik(
                                          fontSize: 12,
                                          color: AppColors.sonicSilver,
                                        ),
                                      ),
                              ),
                            );
                          }

                          // Ajustar índice si hay indicador de carga
                          final msgIndex = _hasMore ? index - 1 : index;
                          final msg = _mensajes[msgIndex];
                          final isMine = msg.remitenteId == currentUserId;
                          final time = _formatTime(msg.creadoEn);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Avatar para mensajes de otros
                                if (!isMine) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      msg.remitenteNombre.isNotEmpty
                                          ? msg.remitenteNombre[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.catamaran(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // Burbuja del mensaje
                                Flexible(
                                  child: GestureDetector(
                                    onLongPress: isMine
                                        ? () => _showMessageOptions(context, msg, msgIndex)
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? AppColors.primary.withOpacity(0.12)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMine
                                            ? const Radius.circular(16)
                                            : const Radius.circular(4),
                                        bottomRight: isMine
                                            ? const Radius.circular(4)
                                            : const Radius.circular(16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nombre del remitente (solo si no es mío y es grupal)
                                        if (!isMine && widget.chat.esGrupal)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              msg.remitenteNombre,
                                              style: GoogleFonts.rubik(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        // Mensaje
                                        if (msg.mensaje.isNotEmpty)
                                          Text(
                                            msg.mensaje,
                                            style: GoogleFonts.rubik(
                                              fontSize: 15,
                                              color: AppColors.richBlack,
                                            ),
                                          ),
                                        // Imagen
                                        if (msg.imagenUrl != null && msg.imagenUrl!.isNotEmpty) ...[
                                          if (msg.mensaje.isNotEmpty) const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: msg.imagenUrl!,
                                              width: 200,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                width: 200,
                                                height: 150,
                                                color: AppColors.lightGray,
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                width: 200,
                                                height: 150,
                                                color: AppColors.lightGray,
                                                child: const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        // Hora y check
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              time,
                                              style: GoogleFonts.rubik(
                                                fontSize: 11,
                                                color: AppColors.sonicSilver,
                                              ),
                                            ),
                                            if (isMine) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                msg.leido
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 15,
                                                color: msg.leido
                                                    ? AppColors.primary
                                                    : AppColors.sonicSilver,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ),
                                ),
                                // Espacio para mensajes míos
                                if (isMine) const SizedBox(width: 50),
                                // Espacio para mensajes de otros
                                if (!isMine) const SizedBox(width: 50),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          // Input de mensaje estilo crear post
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vista previa de imagen
              if (_selectedImage != null)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Barra de entrada
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Botón emoji
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                        ),
                        color: AppColors.sonicSilver,
                        iconSize: 24,
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                            if (_showEmojiPicker) {
                              _focusNode.unfocus();
                            } else {
                              _focusNode.requestFocus();
                            }
                          });
                        },
                      ),
                      // Campo de texto
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: GoogleFonts.rubik(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Escribe algo...',
                            hintStyle: GoogleFonts.rubik(
                              color: AppColors.sonicSilver.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      // Botón imagen
                      IconButton(
                        icon: Icon(
                          _selectedImage != null
                              ? Icons.image
                              : Icons.image_outlined,
                        ),
                        color: _selectedImage != null
                            ? AppColors.primary
                            : AppColors.sonicSilver,
                        iconSize: 24,
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1920,
                            maxHeight: 1920,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setState(() {
                              _selectedImage = File(image.path);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Botón de enviar
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          final isEmpty = _controller.text.trim().isEmpty &&
                              _selectedImage == null;
                          return GestureDetector(
                            onTap: isEmpty ? null : _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isEmpty
                                    ? AppColors.sonicSilver.withOpacity(0.5)
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Selector de emojis
              if (_showEmojiPicker)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: emoji.EmojiPicker(
                    textEditingController: _controller,
                    config: emoji.Config(
                      emojiViewConfig: emoji.EmojiViewConfig(
                        columns: 7,
                        emojiSizeMax: 32.0,
                        backgroundColor: AppColors.background,
                      ),
                      categoryViewConfig: emoji.CategoryViewConfig(
                        indicatorColor: AppColors.primary,
                        iconColorSelected: AppColors.primary,
                        backgroundColor: AppColors.background,
                      ),
                      bottomActionBarConfig: emoji.BottomActionBarConfig(
                        backgroundColor: AppColors.background,
                        buttonColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
