import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _showOnlyUnread = true;
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;
  int _unreadTotal = 0;
  int _allTotal = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Escuchar nuevas notificaciones del sistema para refrescar automáticamente
    _notificationSubscription = PushNotificationService.onNotificationReceived.listen((data) {
      if (data['type'] == 'system_notification' || data['type'] == 'friend_request') {
        if (kDebugMode) print('🔄 Refrescando lista de notificaciones por notificación push');
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _notifications = [];
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _apiService.getNotifications(
        soloNoLeidas: _showOnlyUnread,
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        if (reset) {
          _notifications = result.notifications;
          _isLoading = false;
        } else {
          _notifications.addAll(result.notifications);
          _isLoadingMore = false;
        }
        
        _unreadTotal = result.totalNoLeidas;
        _allTotal = result.totalTodas;

        _offset += result.notifications.length;
        if (result.notifications.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await _apiService.markNotificationRead(notificationId);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    // Marcar todas las notificaciones no leídas como leídas usando el endpoint optimizado
    final success = await _apiService.markAllNotificationsRead();
    if (success) {
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(int id) async {
    final success = await _apiService.deleteNotification(id);
    if (success) {
      _loadNotifications();
    }
  }

  Future<void> _deleteAllNotifications() async {
    final success = await _apiService.deleteNotification(null, deleteAll: true);
    if (success) {
      _loadNotifications();
    }
  }

  int get _unreadCount {
    return _unreadTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.catamaran(
            fontWeight: FontWeight.w800,
            color: AppColors.richBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.richBlack),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (value) {
              if (value == 'mark_read') _markAllAsRead();
              if (value == 'delete_all') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Text('¿Limpiar bandeja?', style: GoogleFonts.catamaran(fontWeight: FontWeight.w900)),
                    content: const Text('¿Estás seguro de que quieres eliminar todas tus notificaciones?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar', style: GoogleFonts.rubik(color: AppColors.sonicSilver)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAllNotifications();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Eliminar todo', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              if (_unreadCount > 0)
                PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text('Marcar todas leídas', style: GoogleFonts.rubik(fontSize: 14)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text('Vaciar bandeja', style: GoogleFonts.rubik(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Filter Tabs
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterTab(
                            label: 'No leídas',
                            count: _unreadCount,
                            isActive: _showOnlyUnread,
                            onTap: () {
                              setState(() {
                                _showOnlyUnread = true;
                              });
                              _loadNotifications(reset: true);
                            },
                          ),
                        ),
                        Expanded(
                          child: _FilterTab(
                            label: 'Todas',
                            count: _allTotal,
                            isActive: !_showOnlyUnread,
                            onTap: () {
                              setState(() {
                                _showOnlyUnread = false;
                              });
                              _loadNotifications(reset: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications List or Empty State
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none,
                                  size: 80,
                                  color: AppColors.lightGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showOnlyUnread
                                      ? 'No hay notificaciones nuevas'
                                      : 'No hay notificaciones',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    color: AppColors.sonicSilver,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                          onRefresh: () => _loadNotifications(reset: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notifications.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _notifications.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : TextButton.icon(
                                            onPressed: () => _loadNotifications(reset: false),
                                            icon: const Icon(Icons.add_circle_outline_rounded),
                                            label: const Text('Ver más'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                              textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              backgroundColor: AppColors.primary.withOpacity(0.05),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                  ),
                                );
                              }
      
                              final notification = _notifications[index];
                              return _NotificationItem(
                                notification: notification,
                                onTap: () {
                                  if (!notification.leida) {
                                    _markAsRead(notification.id);
                                  }
                                },
                                onDelete: () => _deleteNotification(notification.id),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.sonicSilver,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  String _getTimeAgo(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Hace un momento';
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColorForType(notification.tipo);
    final iconData = _getIconForType(notification.tipo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.leida
                ? AppColors.white
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.leida
                  ? AppColors.lightGray
                  : AppColors.primary.withOpacity(0.2),
              width: notification.leida ? 1 : 1.5,
            ),
            boxShadow: notification.leida
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo,
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: notification.leida
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: AppColors.richBlack,
                            ),
                          ),
                        ),
                        if (!notification.leida)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 4, right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.sonicSilver.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.mensaje,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: AppColors.sonicSilver,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTimeAgo(notification.fecha),
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        color: AppColors.sonicSilver.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

