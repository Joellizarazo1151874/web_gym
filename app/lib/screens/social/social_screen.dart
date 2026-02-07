import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../config/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/full_image_viewer.dart';
import 'chat_conversation_screen.dart';
import 'friend_requests_screen.dart';
import 'contacts_screen.dart';
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
                                      SnackBarHelper.show(
                                        context: sheetContext,
                                        message: resp['message']?.toString() ??
                                            'Solicitud enviada',
                                        type: resp['success'] == true
                                            ? SnackBarType.success
                                            : SnackBarType.error,
                                        title: resp['success'] == true
                                            ? '¡Éxito!'
                                            : 'Error',
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

  bool _isFabExtended = true;
  Timer? _fabTimer;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _resetAndShrinkFab();
  }

  void _handleTabSelection() {
    if (_tabController.index != _lastTabIndex) {
      _lastTabIndex = _tabController.index;
      _resetAndShrinkFab();
    }
  }

  void _resetAndShrinkFab() {
    setState(() => _isFabExtended = true);
    _fabTimer?.cancel();
    _fabTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isFabExtended = false);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
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
          toolbarHeight: 64,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: user?.foto != null && user!.foto!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.foto!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          (user?.nombre != null && user!.nombre.isNotEmpty)
                              ? user.nombre[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.catamaran(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
          title: Text(
            'Comunidad',
            style: GoogleFonts.catamaran(
              fontWeight: FontWeight.w900,
              color: AppColors.richBlack,
              fontSize: 22,
            ),
          ),
          actions: const [
            _FriendRequestsButton(),
            SizedBox(width: 12),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.sonicSilver,
            labelStyle: GoogleFonts.rubik(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.rubik(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Publicaciones'),
              Tab(text: 'Mensajes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _PostsTab(key: _postsTabKey),
            const _ChatsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final tabIndex = _tabController.index;
            if (tabIndex == 0) {
              _postsTabKey.currentState?.openCreatePostSheet();
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactsScreen()));
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          isExtended: _isFabExtended,
          icon: Icon(
            _tabController.index == 0 ? Icons.add_rounded : Icons.add_rounded, // Siempre "+" si quieres, o específico
            color: Colors.white,
          ),
          label: Text(
             _tabController.index == 0 ? 'Publicar' : 'Nuevo Chat',
            style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: Colors.white),
          ),
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
  final ScrollController _scrollController = ScrollController();
  List<PostModel> _posts = [];
  bool _loading = true;
  bool _error = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _postsPerPage = 10;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
    
    // Escuchar nuevas publicaciones para refrescar automáticamente
    _notificationSubscription = PushNotificationService.onNotificationReceived.listen((data) {
      if (data['type'] == 'new_post') {
        if (kDebugMode) print('🔄 Refrescando publicaciones por notificación push');
        _loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_loadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  void _updatePostContent(int index, String contenido) {
    if (index < 0 || index >= _posts.length) return;
    final post = _posts[index];
    setState(() {
      _posts[index] = PostModel(
        id: post.id,
        usuarioId: post.usuarioId,
        usuarioNombre: post.usuarioNombre,
        usuarioFoto: post.usuarioFoto,
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
      _currentPage = 0;
      _hasMore = true;
    });
    try {
      final result = await _apiService.getPosts(
        limite: _postsPerPage,
        offset: 0,
      );
      setState(() {
        _posts = result;
        _loading = false;
        _hasMore = result.length >= _postsPerPage;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      _currentPage++;
      final result = await _apiService.getPosts(
        limite: _postsPerPage,
        offset: _currentPage * _postsPerPage,
      );
      setState(() {
        _posts.addAll(result);
        _loadingMore = false;
        _hasMore = result.length >= _postsPerPage;
      });
    } catch (_) {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> openCreatePostSheet() async {
    final parentContext = context;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasActiveMembership = auth.membership?.isActive == true;

    if (!hasActiveMembership) {
      SnackBarHelper.error(
        parentContext,
        'Requiere membresía activa para publicar',
        title: 'Acceso Denegado',
      );
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();
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
                          maxHeight:
                              MediaQuery.of(sheetContext).size.height * 0.3,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
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
                        bottom:
                            MediaQuery.of(sheetContext).viewInsets.bottom + 8,
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
                                        if (showEmojiPicker) {
                                          // Cerrar teclado al abrir emojis
                                          focusNode.unfocus();
                                        } else {
                                          // Abrir teclado al cerrar emojis
                                          focusNode.requestFocus();
                                        }
                                      });
                                    },
                                  ),
                                  // TextField
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      onTap: () {
                                        // Cerrar selector de emojis al tocar el campo de texto
                                        if (showEmojiPicker) {
                                          setModalState(() {
                                            showEmojiPicker = false;
                                          });
                                        }
                                      },
                                      maxLines: 5,
                                      minLines: 1,
                                      maxLength: maxChars,
                                      style: GoogleFonts.rubik(fontSize: 15),
                                      decoration: InputDecoration(
                                        hintText: 'Escribe algo...',
                                        hintStyle: GoogleFonts.rubik(
                                          color: AppColors.sonicSilver
                                              .withOpacity(0.6),
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                      final XFile? image = await picker
                                          .pickImage(
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
                              final isEmpty =
                                  controller.text.trim().isEmpty &&
                                  selectedImage == null;
                              return GestureDetector(
                                onTap: isEmpty
                                    ? null
                                    : () async {
                                        final contenido = controller.text
                                            .trim();
                                        Navigator.of(sheetContext).pop();

                                        // Subir imagen si existe
                                        String? imageUrl;
                                        bool uploadOverlayOpen = false;
                                        bool publishOverlayOpen = false;
                                        try {
                                          if (selectedImage != null &&
                                              parentContext.mounted) {
                                            uploadOverlayOpen = true;
                                            showDialog(
                                              context: parentContext,
                                              useRootNavigator: true,
                                              barrierDismissible: false,
                                              barrierColor: Colors.transparent,
                                              builder: (dialogContext) => Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.richBlack
                                                        .withOpacity(0.85),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                        width: 30,
                                                        height: 30,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 3,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(
                                                                AppColors
                                                                    .primary,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'Subiendo...',
                                                        style:
                                                            GoogleFonts.rubik(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );

                                            imageUrl = await _apiService
                                                .uploadPostImage(
                                                  selectedImage!.path,
                                                );

                                            if (uploadOverlayOpen &&
                                                parentContext.mounted) {
                                              final popped = await Navigator.of(
                                                parentContext,
                                                rootNavigator: true,
                                              ).maybePop();
                                              if (popped) {
                                                uploadOverlayOpen = false;
                                              }
                                            }

                                            if (imageUrl == null) {
                                              if (uploadOverlayOpen &&
                                                  parentContext.mounted) {
                                                Navigator.of(
                                                  parentContext,
                                                  rootNavigator: true,
                                                ).maybePop();
                                                uploadOverlayOpen = false;
                                              }
                                               if (parentContext.mounted) {
                                                 SnackBarHelper.error(
                                                   parentContext,
                                                   'No se pudo subir la imagen',
                                                   title: 'Error de Carga',
                                                 );
                                               }
                                              return;
                                            }
                                          }

                                          if (parentContext.mounted) {
                                            publishOverlayOpen = true;
                                            showDialog(
                                              context: parentContext,
                                              useRootNavigator: true,
                                              barrierDismissible: false,
                                              barrierColor: Colors.transparent,
                                              builder: (dialogContext) => Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.richBlack
                                                        .withOpacity(0.85),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                        width: 30,
                                                        height: 30,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 3,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(
                                                                AppColors
                                                                    .primary,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'Publicando...',
                                                        style:
                                                            GoogleFonts.rubik(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final newPost = await _apiService
                                              .createPost(
                                                contenido:
                                                    contenido.isEmpty &&
                                                        imageUrl == null
                                                    ? '📸'
                                                    : contenido,
                                                imagenUrl: imageUrl,
                                              );

                                          if (publishOverlayOpen &&
                                              parentContext.mounted) {
                                            final popped = await Navigator.of(
                                              parentContext,
                                              rootNavigator: true,
                                            ).maybePop();
                                            if (popped) {
                                              publishOverlayOpen = false;
                                            }
                                          }

                                            if (newPost != null && mounted) {
                                              setState(() {
                                                _posts.insert(0, newPost);
                                              });
                                              SnackBarHelper.success(
                                                parentContext,
                                                'Post publicado exitosamente',
                                                title: '¡Éxito!',
                                              );
                                            } else if (parentContext.mounted) {
                                              SnackBarHelper.error(
                                                parentContext,
                                                'No se pudo publicar el post',
                                                title: 'Error',
                                              );
                                            }
                                        } catch (e) {
                                          if (uploadOverlayOpen &&
                                              parentContext.mounted) {
                                            final popped = await Navigator.of(
                                              parentContext,
                                              rootNavigator: true,
                                            ).maybePop();
                                            if (popped) {
                                              uploadOverlayOpen = false;
                                            }
                                          }
                                          if (publishOverlayOpen &&
                                              parentContext.mounted) {
                                            final popped = await Navigator.of(
                                              parentContext,
                                              rootNavigator: true,
                                            ).maybePop();
                                            if (popped) {
                                              publishOverlayOpen = false;
                                            }
                                          }
                                          if (parentContext.mounted) {
                                            SnackBarHelper.error(
                                              parentContext,
                                              'No se pudo publicar el post',
                                              title: 'Error de Red',
                                            );
                                          }
                                        } finally {
                                          if (uploadOverlayOpen &&
                                              parentContext.mounted) {
                                            Navigator.of(
                                              parentContext,
                                              rootNavigator: true,
                                            ).maybePop();
                                            uploadOverlayOpen = false;
                                          }
                                          if (publishOverlayOpen &&
                                              parentContext.mounted) {
                                            Navigator.of(
                                              parentContext,
                                              rootNavigator: true,
                                            ).maybePop();
                                            publishOverlayOpen = false;
                                          }
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
                            categoryViewConfig:
                                const emoji.CategoryViewConfig(),
                            bottomActionBarConfig:
                                const emoji.BottomActionBarConfig(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Error al cargar posts',
              style: GoogleFonts.rubik(color: AppColors.sonicSilver),
            ),
            TextButton(
              onPressed: _loadPosts,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPosts,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Icon(Icons.post_add_rounded, size: 80, color: AppColors.gainsboro),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Aún no hay publicaciones.\n¡Sé el primero en compartir algo!',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  color: AppColors.sonicSilver,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _posts.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _posts[index];
          final initial = post.usuarioNombre.isNotEmpty
              ? post.usuarioNombre.trim()[0].toUpperCase()
              : 'U';
          final isOwner = currentUserId != null && currentUserId == post.usuarioId;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del Post
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                        ),
                        child: ClipOval(
                          child: post.usuarioFoto != null
                              ? CachedNetworkImage(
                                  imageUrl: post.usuarioFoto!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.catamaran(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.catamaran(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.catamaran(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.usuarioNombre,
                              style: GoogleFonts.catamaran(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.richBlack,
                              ),
                            ),
                            if (post.hace != null && post.hace!.isNotEmpty)
                              Text(
                                post.hace!,
                                style: GoogleFonts.rubik(
                                  fontSize: 11,
                                  color: AppColors.sonicSilver,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, size: 22, color: AppColors.sonicSilver),
                        onPressed: () => _showPostOptions(context, post, index, isOwner),
                      ),
                    ],
                  ),
                ),
                
                // Contenido del Post
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    post.contenido,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.richBlack.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ),
                
                // Imagen del post
                if (post.imagenUrl != null && post.imagenUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => showFullImage(context, post.imagenUrl!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: post.imagenUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 250,
                            color: AppColors.gainsboro.withOpacity(0.3),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: AppColors.gainsboro.withOpacity(0.3),
                            child: const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.sonicSilver),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Footer del Post (Likes)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleLike(index),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  post.likedByCurrent ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 22,
                                  color: post.likedByCurrent ? AppColors.error : AppColors.sonicSilver,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${post.likesCount}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: post.likedByCurrent ? AppColors.error : AppColors.sonicSilver,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Podrías añadir botón de comentarios aquí en el futuro
                    ],
                  ),
                ),
              ],
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
                  final editFocusNode = FocusNode();

                  final shouldSave = await showModalBottomSheet<bool>(
                    context: parentContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (modalContext) {
                      bool showEmojiPicker = false;
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Container(
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('lib/img/fondo.png'),
                                fit: BoxFit.cover,
                                repeat: ImageRepeat.repeat,
                                opacity: 0.2,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: SafeArea(
                                top: false,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 16,
                                        bottom: showEmojiPicker
                                            ? 0
                                            : MediaQuery.of(modalContext)
                                                    .viewInsets.bottom +
                                                16,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Campo de texto con botones integrados (igual al chat)
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    22,
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // Botón emoji
                                                    IconButton(
                                                      icon: Icon(
                                                        showEmojiPicker
                                                            ? Icons.keyboard
                                                            : Icons
                                                                .emoji_emotions_outlined,
                                                        color:
                                                            AppColors.sonicSilver,
                                                        size: 22,
                                                      ),
                                                      onPressed: () {
                                                        setModalState(() {
                                                          showEmojiPicker =
                                                              !showEmojiPicker;
                                                          if (showEmojiPicker) {
                                                            editFocusNode
                                                                .unfocus();
                                                          } else {
                                                            editFocusNode
                                                                .requestFocus();
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    // Campo de texto
                                                    Expanded(
                                                      child: TextField(
                                                        controller: controller,
                                                        focusNode: editFocusNode,
                                                        onTap: () {
                                                          // Cerrar selector de emojis al tocar el campo de texto
                                                          if (showEmojiPicker) {
                                                            setModalState(() {
                                                              showEmojiPicker =
                                                                  false;
                                                            });
                                                          }
                                                        },
                                                        maxLines: 5,
                                                        minLines: 1,
                                                        keyboardType:
                                                            TextInputType
                                                                .multiline,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        style: GoogleFonts.rubik(
                                                          fontSize: 15,
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'Escribe algo...',
                                                          hintStyle:
                                                              GoogleFonts.rubik(
                                                            color: AppColors
                                                                .sonicSilver
                                                                .withOpacity(
                                                                    0.6),
                                                          ),
                                                          border:
                                                              InputBorder.none,
                                                          enabledBorder:
                                                              InputBorder.none,
                                                          focusedBorder:
                                                              InputBorder.none,
                                                          errorBorder:
                                                              InputBorder.none,
                                                          focusedErrorBorder:
                                                              InputBorder.none,
                                                          disabledBorder:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 10,
                                                          ),
                                                        ),
                                                        autofocus: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Botón de enviar (igual al chat)
                                            AnimatedBuilder(
                                              animation: controller,
                                              builder: (_, __) {
                                                final isEmpty = controller.text
                                                    .trim()
                                                    .isEmpty;
                                                return GestureDetector(
                                                  onTap: isEmpty
                                                      ? null
                                                      : () {
                                                          if (controller.text
                                                                  .trim()
                                                                  .isNotEmpty) {
                                                            Navigator.of(
                                                              modalContext,
                                                            ).pop(true);
                                                          }
                                                        },
                                                  child: Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: isEmpty
                                                          ? AppColors
                                                                  .sonicSilver
                                                              .withOpacity(0.5)
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
                                    if (showEmojiPicker)
                                      SizedBox(
                                        height: MediaQuery.of(context)
                                                .size
                                                .height *
                                            0.35,
                                        child: emoji.EmojiPicker(
                                          textEditingController: controller,
                                          config: emoji.Config(
                                            emojiViewConfig:
                                                emoji.EmojiViewConfig(
                                              columns: 7,
                                              emojiSizeMax: 32.0,
                                              backgroundColor:
                                                  AppColors.background,
                                            ),
                                            categoryViewConfig:
                                                emoji.CategoryViewConfig(
                                              indicatorColor: AppColors.primary,
                                              iconColorSelected:
                                                  AppColors.primary,
                                              backgroundColor:
                                                  AppColors.background,
                                            ),
                                            bottomActionBarConfig:
                                                const emoji
                                                    .BottomActionBarConfig(
                                              enabled: false,
                                            ),
                                            skinToneConfig:
                                                const emoji.SkinToneConfig(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );

                  editFocusNode.dispose();

                  if (shouldSave == true) {
                    if (controller.text.trim().isEmpty) {
                      if (parentContext.mounted) {
                        SnackBarHelper.warning(
                          parentContext,
                          'Escribe algo para publicar',
                          title: 'Contenido Vacío',
                        );
                      }
                      controller.dispose();
                      return;
                    }

                    final ok = await api.updatePost(
                      postId: post.id,
                      contenido: controller.text.trim(),
                    );
                    if (ok && parentContext.mounted) {
                      final state = parentContext
                          .findAncestorStateOfType<_PostsTabState>();
                      state?._updatePostContent(index, controller.text.trim());
                      SnackBarHelper.success(parentContext, 'Post actualizado', title: 'Éxito');
                    } else if (!ok && parentContext.mounted) {
                      SnackBarHelper.error(
                        parentContext,
                        'No se pudo editar el post',
                        title: 'Error',
                      );
                    }
                    controller.dispose();
                  } else {
                    controller.dispose();
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
                  final resp = await api.reportPost(
                    post.id,
                    'Contenido inapropiado',
                  );
                  if (parentContext.mounted) {
                    if (resp == true) {
                      final state = parentContext
                          .findAncestorStateOfType<_PostsTabState>();
                      state?._removePostAt(index);
                    }
                    SnackBarHelper.show(
                      context: parentContext,
                      message: resp ? 'Post reportado exitosamente' : 'No se pudo reportar el post',
                      type: resp ? SnackBarType.success : SnackBarType.error,
                      title: resp ? '¡Reportado!' : 'Error',
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
                    SnackBarHelper.show(
                      context: parentContext,
                      message: resp['success'] == true ? 'Solicitud enviada exitosamente' : (resp['message']?.toString() ?? 'No se pudo enviar la solicitud'),
                      type: resp['success'] == true ? SnackBarType.success : SnackBarType.error,
                      title: resp['success'] == true ? '¡Éxito!' : 'Error',
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

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  List<ChatModel> _chats = [];
  bool _loading = true;
  String? _errorMessage;
  StreamSubscription? _notificationSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    
    // Escuchar notificaciones para refrescar la lista de chats automáticamente
    _notificationSubscription = PushNotificationService.onNotificationReceived.listen((data) async {
      final type = data['type'];
      if (type == 'chat_message' || type == 'friend_request' || 
          type == 'system_notification' || type == 'new_chat' || type == 'chat_deleted') {
        if (kDebugMode) print('🔄 Refrescando lista de chats por notificación push ($type)');
        // Pequeño retraso para asegurar que el servidor haya procesado todo
        await Future.delayed(const Duration(milliseconds: 500));
        _loadChats();
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.getChats();
      if (mounted) {
        setState(() {
          _chats = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Error al cargar chats';
        });
      }
    }
  }

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
                      final ok = await _apiService.deleteChat(chat.id);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading && _chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.rubik(color: AppColors.sonicSilver),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChats,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Icon(Icons.chat_bubble_outline_rounded,
                size: 80, color: AppColors.gainsboro),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Aún no tienes chats.\n¡Inicia una conversación!',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  color: AppColors.sonicSilver,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final initial =
              chat.nombre.isNotEmpty ? chat.nombre[0].toUpperCase() : '?';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2), width: 1.5),
                ),
                child: ClipOval(
                  child: chat.foto != null && chat.foto!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: chat.foto!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: chat.esGrupal
                                ? const Icon(Icons.group_rounded,
                                    color: AppColors.primary, size: 24)
                                : Text(
                                    initial,
                                    style: GoogleFonts.catamaran(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: chat.esGrupal
                                ? const Icon(Icons.group_rounded,
                                    color: AppColors.primary, size: 24)
                                : Text(
                                    initial,
                                    style: GoogleFonts.catamaran(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        )
                      : Center(
                          child: chat.esGrupal
                              ? const Icon(Icons.group_rounded,
                                  color: AppColors.primary, size: 24)
                              : Text(
                                  initial,
                                  style: GoogleFonts.catamaran(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                ),
              ),
              title: Text(
                chat.nombre,
                style: GoogleFonts.catamaran(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.richBlack,
                ),
              ),
              subtitle: Text(
                chat.ultimoMensaje ?? 'Sin mensajes aún',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  color: AppColors.sonicSilver,
                  fontWeight:
                      chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chat.ultimoMensajeEn != null)
                    Text(
                      _formatLastMessageTime(chat.ultimoMensajeEn!),
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        color: chat.unreadCount > 0
                            ? AppColors.primary
                            : AppColors.sonicSilver,
                        fontWeight: chat.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatConversationScreen(chat: chat),
                  ),
                );
                // Recargar chats al volver
                _loadChats();
              },
              onLongPress: () => _showChatOptions(context, chat, () {
                _loadChats();
              }),
            ),
          );
        },
      ),
    );
  }

  String _formatLastMessageTime(String? datetime) {
    if (datetime == null) return '';
    try {
      final dt = DateTime.parse(datetime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays < 7) {
        const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        return dias[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }
}
