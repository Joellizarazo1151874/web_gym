import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'dart:io';
import '../../config/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'chat_conversation_screen.dart';
import 'friend_requests_screen.dart';
import '../../models/search_user_model.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_PostsTabState> _postsTabKey = GlobalKey<_PostsTabState>();
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  Future<void> _openUserSearchSheet(BuildContext context) async {
    final controller = TextEditingController();
    List<SearchUserModel> results = [];
    bool searching = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setStateSheet) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buscar usuario',
                          style: GoogleFonts.catamaran(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.richBlack,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.sonicSilver,
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Nombre o email del usuario',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            setStateSheet(() {
                              searching = true;
                            });
                            results = await _apiService.searchUsers(
                              controller.text.trim(),
                            );
                            setStateSheet(() {
                              searching = false;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) async {
                        setStateSheet(() {
                          searching = true;
                        });
                        results = await _apiService.searchUsers(
                          controller.text.trim(),
                        );
                        setStateSheet(() {
                          searching = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (searching)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Escribe un nombre o email para buscar usuarios.',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: AppColors.sonicSilver,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final user = results[index];
                            final initial = user.nombreCompleto.isNotEmpty
                                ? user.nombreCompleto[0].toUpperCase()
                                : '?';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  initial,
                                  style: GoogleFonts.catamaran(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.nombreCompleto,
                                style: GoogleFonts.rubik(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: AppColors.sonicSilver,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  final resp = await _apiService
                                      .sendFriendRequest(user.id);
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          resp['message']?.toString() ??
                                              'Solicitud enviada',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Solicitar'),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comunidad',
          style: GoogleFonts.catamaran(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.sonicSilver,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Chats'),
          ],
        ),
        actions: const [_FriendRequestsButton()],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostsTab(key: _postsTabKey),
          const _ChatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final tabIndex = _tabController.index;
          if (tabIndex == 0) {
            _postsTabKey.currentState?.openCreatePostSheet();
          } else {
            await _openUserSearchSheet(context);
          }
        },
        child: Icon(
          _tabController.index == 0 ? Icons.add : Icons.chat_bubble_outline,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FriendRequestsButton extends StatefulWidget {
  const _FriendRequestsButton();

  @override
  State<_FriendRequestsButton> createState() => _FriendRequestsButtonState();
}

class _FriendRequestsButtonState extends State<_FriendRequestsButton> {
  final ApiService _apiService = ApiService();
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final list = await _apiService.getFriendRequests();
    if (!mounted) return;
    setState(() {
      _pendingCount = list.length;
    });
  }

  Future<void> _openRequests(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendRequestsScreen(onChanged: _loadRequests),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _openRequests(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.person_add_alt_1_outlined),
          if (_pendingCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _pendingCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Solicitudes recibidas',
    );
  }
}

class _PostsTab extends StatefulWidget {
  const _PostsTab({super.key});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final ApiService _apiService = ApiService();
  List<PostModel> _posts = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _updatePostContent(int index, String contenido) {
    if (index < 0 || index >= _posts.length) return;
    final post = _posts[index];
    setState(() {
      _posts[index] = PostModel(
        id: post.id,
        usuarioId: post.usuarioId,
        usuarioNombre: post.usuarioNombre,
        contenido: contenido,
        imagenUrl: post.imagenUrl,
        creadoEn: post.creadoEn,
        hace: post.hace,
        likesCount: post.likesCount,
        likedByCurrent: post.likedByCurrent,
      );
    });
  }

  void _removePostAt(int index) {
    if (index < 0 || index >= _posts.length) return;
    setState(() {
      _posts.removeAt(index);
    });
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await _apiService.getPosts();
      setState(() {
        _posts = result;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> openCreatePostSheet() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasActiveMembership = auth.membership?.isActive == true;

    if (!hasActiveMembership) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solo usuarios con membresía activa pueden publicar.',
            style: GoogleFonts.rubik(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    const maxChars = 280;
    File? selectedImage;
    bool showEmojiPicker = false;
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFECE5DD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header compacto
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            color: Colors.white,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Nuevo post',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          AnimatedBuilder(
                            animation: controller,
                            builder: (_, __) {
                              final length = controller.text.length;
                              final isNearLimit = length > maxChars * 0.8;
                              return Text(
                                '$length',
                                style: GoogleFonts.rubik(
                                  fontSize: 12,
                                  color: isNearLimit 
                                      ? Colors.orange.shade200
                                      : Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Imagen seleccionada (si hay)
                    if (selectedImage != null)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                    
                    // Área de input estilo WhatsApp
                    Container(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Campo de texto
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Botón emoji
                                  IconButton(
                                    icon: Icon(
                                      showEmojiPicker 
                                          ? Icons.keyboard 
                                          : Icons.emoji_emotions_outlined,
                                      color: AppColors.sonicSilver,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        showEmojiPicker = !showEmojiPicker;
                                      });
                                    },
                                  ),
                                  // TextField
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      maxLines: 5,
                                      minLines: 1,
                                      maxLength: maxChars,
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
                                        disabledBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        counterText: '',
                                      ),
                                    ),
                                  ),
                                  // Botón imagen
                                  IconButton(
                                    icon: Icon(
                                      selectedImage != null 
                                          ? Icons.image 
                                          : Icons.image_outlined,
                                      color: selectedImage != null 
                                          ? AppColors.primary 
                                          : AppColors.sonicSilver,
                                      size: 22,
                                    ),
                                    onPressed: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1920,
                                        maxHeight: 1920,
                                        imageQuality: 85,
                                      );
                                      if (image != null) {
                                        setModalState(() {
                                          selectedImage = File(image.path);
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón enviar
                          AnimatedBuilder(
                            animation: controller,
                            builder: (_, __) {
                              final isEmpty = controller.text.trim().isEmpty && selectedImage == null;
                              return GestureDetector(
                                onTap: isEmpty
                                    ? null
                                    : () async {
                                        final contenido = controller.text.trim();
                                        Navigator.of(sheetContext).pop();
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Publicando...',
                                                    style: GoogleFonts.rubik(),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        
                                        // TODO: Subir imagen al servidor si existe
                                        final newPost = await _apiService.createPost(
                                          contenido: contenido.isEmpty ? '📸' : contenido,
                                        );
                                        
                                        if (newPost != null && mounted) {
                                          setState(() {
                                            _posts.insert(0, newPost);
                                          });
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '¡Post publicado!',
                                                    style: GoogleFonts.rubik(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isEmpty
                                        ? AppColors.sonicSilver.withOpacity(0.3)
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: isEmpty 
                                        ? AppColors.sonicSilver
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Picker de emojis
                    if (showEmojiPicker)
                      SizedBox(
                        height: 250,
                        child: emoji.EmojiPicker(
                          onEmojiSelected: (category, emojiItem) {
                            controller.text += emojiItem.emoji;
                          },
                          config: emoji.Config(
                            height: 256,
                            checkPlatformCompatibility: true,
                            emojiViewConfig: emoji.EmojiViewConfig(
                              emojiSizeMax: 28,
                              backgroundColor: const Color(0xFFECE5DD),
                            ),
                            skinToneConfig: const emoji.SkinToneConfig(),
                            categoryViewConfig: const emoji.CategoryViewConfig(),
                            bottomActionBarConfig: const emoji.BottomActionBarConfig(
                              enabled: false,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleLike(int index) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasActiveMembership = auth.membership?.isActive == true;
    if (!hasActiveMembership) return;

    final post = _posts[index];
    final result = await _apiService.togglePostLike(post.id);
    if (result['success'] == true && mounted) {
      setState(() {
        _posts[index] = PostModel(
          id: post.id,
          usuarioId: post.usuarioId,
          usuarioNombre: post.usuarioNombre,
          contenido: post.contenido,
          imagenUrl: post.imagenUrl,
          creadoEn: post.creadoEn,
          hace: post.hace,
          likesCount: result['likes_count'] ?? post.likesCount,
          likedByCurrent: result['liked'] ?? post.likedByCurrent,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.id;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Text(
          'Error al cargar posts',
          style: GoogleFonts.rubik(color: AppColors.sonicSilver),
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Aún no hay publicaciones.\nSé el primero en compartir algo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(color: AppColors.sonicSilver),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final initial = post.usuarioNombre.isNotEmpty
              ? post.usuarioNombre.trim()[0].toUpperCase()
              : 'U';
          final isOwner =
              currentUserId != null && currentUserId == post.usuarioId;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          initial,
                          style: GoogleFonts.catamaran(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.usuarioNombre,
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (post.hace != null && post.hace!.isNotEmpty)
                            Text(
                              post.hace!,
                              style: GoogleFonts.rubik(
                                fontSize: 12,
                                color: AppColors.sonicSilver,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: AppColors.sonicSilver,
                        ),
                        onPressed: () =>
                            _showPostOptions(context, post, index, isOwner),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.contenido,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.richBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLike(index),
                        child: Row(
                          children: [
                            Icon(
                              post.likedByCurrent
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: post.likedByCurrent
                                  ? AppColors.error
                                  : AppColors.sonicSilver,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.likesCount} me gusta',
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: AppColors.sonicSilver,
                              ),
                            ),
                          ],
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
    );
  }
}

void _showPostOptions(
  BuildContext parentContext,
  PostModel post,
  int index,
  bool isOwner,
) async {
  final api = ApiService();

  await showModalBottomSheet<void>(
    context: parentContext,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar post'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final controller = TextEditingController(
                    text: post.contenido,
                  );
                  final shouldSave = await showDialog<bool>(
                    context: parentContext,
                    builder: (_) => AlertDialog(
                      title: const Text('Editar post'),
                      content: TextField(controller: controller, maxLines: 4),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(parentContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(parentContext).pop(true),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  );
                  if (shouldSave == true && controller.text.trim().isNotEmpty) {
                    final ok = await api.updatePost(
                      postId: post.id,
                      contenido: controller.text.trim(),
                    );
                    if (ok && parentContext.mounted) {
                      final state = parentContext
                          .findAncestorStateOfType<_PostsTabState>();
                      state?._updatePostContent(index, controller.text.trim());
                    }
                  }
                },
              ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Eliminar post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirm = await showDialog<bool>(
                    context: parentContext,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar post'),
                      content: const Text(
                        '¿Seguro que deseas eliminar este post?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(parentContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(parentContext).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await api.deletePost(post.id);
                    if (ok && parentContext.mounted) {
                      final state = parentContext
                          .findAncestorStateOfType<_PostsTabState>();
                      state?._removePostAt(index);
                    }
                  }
                },
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text(
                  'Reportar post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final resp = await api.reportPost(post.id, 'Contenido inapropiado');
                  if (parentContext.mounted) {
                    if (resp == true) {
                      final state = parentContext
                          .findAncestorStateOfType<_PostsTabState>();
                      state?._removePostAt(index);
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          resp ? 'Post reportado correctamente' : 'Error al reportar post',
                        ),
                      ),
                    );
                  }
                },
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Enviar solicitud de chat'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final resp = await api.sendFriendRequest(post.usuarioId);
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          resp['message']?.toString() ?? 'Solicitud enviada',
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      );
    },
  );
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    Future<void> _showChatOptions(
      BuildContext parentContext,
      ChatModel chat,
      VoidCallback onDeleted,
    ) async {
      await showModalBottomSheet<void>(
        context: parentContext,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Ver participantes'),
                  onTap: () async {
                    final participantes = await apiService.getChatParticipants(
                      chat.id,
                    );
                    Navigator.of(sheetContext).pop();
                    if (parentContext.mounted) {
                      showDialog(
                        context: parentContext,
                        builder: (_) => AlertDialog(
                          title: const Text('Participantes'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: participantes.isEmpty
                                ? const Text('Sin participantes.')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: participantes.length,
                                    itemBuilder: (context, index) {
                                      final p = participantes[index];
                                      return ListTile(
                                        dense: true,
                                        title: Text(p.nombreCompleto),
                                        subtitle: Text(p.email),
                                      );
                                    },
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(parentContext).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Agregar participante'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final controller = TextEditingController();
                    if (parentContext.mounted) {
                      final result = await showDialog<bool>(
                        context: parentContext,
                        builder: (_) => AlertDialog(
                          title: const Text('Agregar por email'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'correo@ejemplo.com',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(parentContext).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(parentContext).pop(true),
                              child: const Text('Agregar'),
                            ),
                          ],
                        ),
                      );
                      if (result == true && controller.text.trim().isNotEmpty) {
                        final resp = await apiService.addChatParticipant(
                          chatId: chat.id,
                          email: controller.text.trim(),
                        );
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                resp ? 'Participante agregado correctamente' : 'Error al agregar participante',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Eliminar chat',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (parentContext.mounted) {
                      final confirm = await showDialog<bool>(
                        context: parentContext,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar chat'),
                          content: const Text(
                            '¿Seguro que deseas eliminar este chat? Esta acción no se puede deshacer.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(parentContext).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(parentContext).pop(true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final ok = await apiService.deleteChat(chat.id);
                        if (ok && parentContext.mounted) {
                          onDeleted();
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    return FutureBuilder<List<ChatModel>>(
      future: apiService.getChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar chats',
              style: GoogleFonts.rubik(color: AppColors.sonicSilver),
            ),
          );
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes chats.\nCrea uno nuevo desde el botón (+).',
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(color: AppColors.sonicSilver),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setStateChats) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = chats[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.shadow1,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        chat.esGrupal ? Icons.group : Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      chat.nombre,
                      style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      chat.ultimoMensaje ?? 'Sin mensajes aún',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: AppColors.sonicSilver,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(chat: chat),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showChatOptions(context, chat, () {
                        setStateChats(() {
                          chats.removeAt(index);
                        });
                      });
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
