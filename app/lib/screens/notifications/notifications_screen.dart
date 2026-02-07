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
  bool _isLoading = true;
  bool _showOnlyUnread = false;
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

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _apiService.getNotifications(
        soloNoLeidas: _showOnlyUnread,
      );
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  int get _unreadCount {
    return _notifications.where((n) => !n.leida).length;
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
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(
                Icons.done_all,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Marcar todas',
                style: GoogleFonts.rubik(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
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
                              label: 'Todas',
                              count: _notifications.length,
                              isActive: !_showOnlyUnread,
                              onTap: () {
                                setState(() {
                                  _showOnlyUnread = false;
                                });
                                _loadNotifications();
                              },
                            ),
                          ),
                          Expanded(
                            child: _FilterTab(
                              label: 'No leídas',
                              count: _unreadCount,
                              isActive: _showOnlyUnread,
                              onTap: () {
                                setState(() {
                                  _showOnlyUnread = true;
                                });
                                _loadNotifications();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notifications List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _NotificationItem(
                              notification: notification,
                              onTap: () {
                                if (!notification.leida) {
                                  _markAsRead(notification.id);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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

  const _NotificationItem({
    required this.notification,
    required this.onTap,
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
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
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

