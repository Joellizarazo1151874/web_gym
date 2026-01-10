import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../models/contact_model.dart';
import '../../models/chat_model.dart';
import '../../services/api_service.dart';
import 'chat_conversation_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ApiService _apiService = ApiService();
  List<ContactModel> _contactos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Apodo eliminado',
                          style: GoogleFonts.rubik(),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
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
              child: Text(
                'Cancelar',
                style: GoogleFonts.rubik(),
              ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Apodo actualizado',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
              child: Text(
                'Cancelar',
                style: GoogleFonts.rubik(),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final ok = await _apiService.removeContact(contacto.contactoId);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Contacto eliminado',
                        style: GoogleFonts.rubik(),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(chat: chat),
        ),
      );
    }
  }

  Future<ChatModel?> _createOrGetPrivateChat(ContactModel contacto) async {
    // Obtener todos los chats del usuario
    final chats = await _apiService.getChats();

    // Buscar si ya existe un chat privado con este contacto
    for (final chat in chats) {
      if (!chat.esGrupal) {
        // Verificar si este chat es con el contacto
        final participantes =
            await _apiService.getChatParticipants(chat.id);
        if (participantes.length == 2) {
          final tieneContacto =
              participantes.any((p) => p.id == contacto.contactoId);
          if (tieneContacto) {
            // Usar el apodo si existe, sino el nombre del contacto
            return ChatModel(
              id: chat.id,
              nombre: contacto.nombreMostrar,
              esGrupal: false,
              creadoEn: chat.creadoEn,
              ultimoMensaje: chat.ultimoMensaje,
              ultimoMensajeEn: chat.ultimoMensajeEn,
              ultimoRemitente: chat.ultimoRemitente,
            );
          }
        }
      }
    }

    // Si no existe, mostrar mensaje de que debe iniciarlo desde la pantalla de chats
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Envíale un mensaje desde la pantalla de chats',
            style: GoogleFonts.rubik(),
          ),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Contactos',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contactos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppColors.sonicSilver.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes contactos aún',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          color: AppColors.sonicSilver,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busca usuarios y envíales solicitudes',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          color: AppColors.sonicSilver.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContacts,
                  child: ListView.builder(
                    itemCount: _contactos.length,
                    itemBuilder: (context, index) {
                      final contacto = _contactos[index];
                      final inicial =
                          contacto.nombreMostrar[0].toUpperCase();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withOpacity(0.1),
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
                          style: GoogleFonts.rubik(
                            fontWeight: FontWeight.w600,
                          ),
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
                    },
                  ),
                ),
    );
  }
}
