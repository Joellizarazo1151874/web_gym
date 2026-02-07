import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../models/contact_model.dart';
import '../../models/chat_model.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../models/search_user_model.dart';
import 'chat_conversation_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ApiService _apiService = ApiService();
  List<ContactModel> _contactos = [];
  List<SearchUserModel> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contactFilterController =
      TextEditingController();
  String _contactFilter = '';
  bool _searching = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final result = await _apiService.getContacts();
      setState(() {
        _contactos = result;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _searching = true;
    });
    final results = await _apiService.searchUsers(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  List<ContactModel> _getFilteredContacts() {
    if (_contactFilter.isEmpty) return _contactos;
    final q = _contactFilter.toLowerCase();
    return _contactos.where((c) {
      return c.nombreMostrar.toLowerCase().contains(q) ||
          (c.nombreReal.toLowerCase().contains(q)) ||
          (c.apodoContacto?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _openFilterSheet() {
    _contactFilterController.text = _contactFilter;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar contactos',
                style: GoogleFonts.catamaran(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contactFilterController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Nombre, apodo o correo',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _contactFilter = val.trim();
                  });
                },
                onSubmitted: (val) {
                  setState(() {
                    _contactFilter = val.trim();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactOptions(ContactModel contacto) {
    showModalBottomSheet<void>(
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
              // Header con nombre del contacto
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        contacto.nombreMostrar[0].toUpperCase(),
                        style: GoogleFonts.catamaran(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contacto.nombreMostrar,
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (contacto.apodoContacto != null)
                            Text(
                              contacto.nombreReal,
                              style: GoogleFonts.rubik(
                                fontSize: 12,
                                color: AppColors.sonicSilver,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Opción: Cambiar apodo
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(
                  contacto.apodoContacto != null
                      ? 'Cambiar apodo'
                      : 'Poner apodo',
                  style: GoogleFonts.rubik(),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNicknameDialog(contacto);
                },
              ),
              // Opción: Eliminar contacto
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: Text(
                  'Eliminar contacto',
                  style: GoogleFonts.rubik(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmRemoveContact(contacto);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showNicknameDialog(ContactModel contacto) {
    final controller = TextEditingController(text: contacto.apodoContacto);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Apodo',
            style: GoogleFonts.catamaran(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nombre real: ${contacto.nombreReal}',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  color: AppColors.sonicSilver,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Ej: Mejor amigo',
                  hintStyle: GoogleFonts.rubik(),
                  border: const OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
            ],
          ),
          actions: [
            if (contacto.apodoContacto != null)
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final ok = await _apiService.updateContactNickname(
                    contacto.contactoId,
                    null,
                  );
                  if (ok && mounted) {
                    SnackBarHelper.success(context, 'Apodo eliminado', title: 'Éxito');
                    _loadContacts();
                  }
                },
                child: Text(
                  'Quitar apodo',
                  style: GoogleFonts.rubik(color: Colors.grey),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: GoogleFonts.rubik()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final apodo = controller.text.trim();
                if (apodo.isEmpty) return;

                final ok = await _apiService.updateContactNickname(
                  contacto.contactoId,
                  apodo,
                );
                if (ok && mounted) {
                  SnackBarHelper.success(context, 'Apodo actualizado', title: 'Éxito');
                  _loadContacts();
                }
              },
              child: Text(
                'Guardar',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveContact(ContactModel contacto) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Eliminar contacto',
            style: GoogleFonts.catamaran(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar a ${contacto.nombreMostrar} de tus contactos?',
            style: GoogleFonts.rubik(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: GoogleFonts.rubik()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final ok = await _apiService.removeContact(contacto.contactoId);
                if (ok && mounted) {
                  SnackBarHelper.success(context, 'Contacto eliminado', title: 'Éxito');
                  _loadContacts();
                }
              },
              child: Text(
                'Eliminar',
                style: GoogleFonts.rubik(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openChatWith(ContactModel contacto) async {
    // Buscar o crear chat privado con este contacto
    final chat = await _createOrGetPrivateChat(contacto);
    if (chat != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatConversationScreen(chat: chat)),
      );
    }
  }

  Future<ChatModel?> _createOrGetPrivateChat(ContactModel contacto) async {
    // Intentar crear o reutilizar un chat privado vía backend
    final chat = await _apiService.createPrivateChat(contacto.contactoId);
    if (chat != null && mounted) {
      return chat;
    }
    if (mounted) {
      SnackBarHelper.error(
        context,
        'No se pudo abrir el chat con este contacto',
        title: 'Error',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredContacts();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Contactos',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadContacts();
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enviar solicitud',
                          style: GoogleFonts.catamaran(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o correo',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _searchUsers,
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _searchUsers(),
                        ),
                        const SizedBox(height: 12),
                        if (_searching)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_searchController.text.isNotEmpty &&
                            _searchResults.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Sin resultados',
                              style: GoogleFonts.rubik(
                                color: AppColors.sonicSilver,
                              ),
                            ),
                          )
                        else if (_searchResults.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resultados',
                                style: GoogleFonts.rubik(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.richBlack,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._searchResults.map(
                                (u) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      (u.nombreCompleto.isNotEmpty
                                              ? u.nombreCompleto[0]
                                              : (u.email.isNotEmpty
                                                    ? u.email[0]
                                                    : '?'))
                                          .toUpperCase(),
                                      style: GoogleFonts.catamaran(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    u.nombreCompleto.isNotEmpty
                                        ? u.nombreCompleto
                                        : u.email,
                                    style: GoogleFonts.rubik(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    u.email,
                                    style: GoogleFonts.rubik(
                                      fontSize: 12,
                                      color: AppColors.sonicSilver,
                                    ),
                                  ),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final resp = await _apiService
                                          .sendFriendRequest(u.id);
                                      if (!mounted) return;
                                      SnackBarHelper.show(
                                        context: context,
                                        message: resp['message']?.toString() ??
                                            'Solicitud enviada exitosamente',
                                        type: resp['success'] == true
                                            ? SnackBarType.success
                                            : SnackBarType.error,
                                        title: resp['success'] == true
                                            ? '¡Éxito!'
                                            : 'Error',
                                      );
                                    },
                                    child: const Text('Solicitar'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Tus contactos',
                      style: GoogleFonts.catamaran(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 32,
                                color: AppColors.sonicSilver.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No tienes contactos aún. Busca usuarios y envía solicitudes.',
                                  style: GoogleFonts.rubik(
                                    color: AppColors.sonicSilver,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((contacto) {
                      final inicial = contacto.nombreMostrar[0].toUpperCase();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            inicial,
                            style: GoogleFonts.catamaran(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          contacto.nombreMostrar,
                          style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                        ),
                        subtitle: contacto.apodoContacto != null
                            ? Text(
                                contacto.nombreReal,
                                style: GoogleFonts.rubik(
                                  fontSize: 12,
                                  color: AppColors.sonicSilver,
                                ),
                              )
                            : null,
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onTap: () => _openChatWith(contacto),
                        onLongPress: () => _showContactOptions(contacto),
                      );
                    }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openFilterSheet,
        child: const Icon(Icons.search),
      ),
    );
  }
}
