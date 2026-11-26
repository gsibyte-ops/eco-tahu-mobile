import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/local_cache_service.dart';
import '../theme/app_theme.dart';
import '../services/secure_storage_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/shimmer_skeletons.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _token = await SecureStorageService.readToken();

    // 1. Tampilkan cache lokal secara instan saat offline/buka halaman
    final cached = await LocalCacheService.readJson(LocalCacheService.keyNotifications);
    if (cached is Map && cached['data'] is List && mounted) {
      final cachedList = (cached['data'] as List)
          .whereType<Map>()
          .map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      setState(() {
        _notifications = cachedList;
        _isLoading = false;
      });
    } else if (_notifications.isEmpty && mounted) {
      setState(() => _isLoading = true);
    }

    if (_token != null && _token!.isNotEmpty) {
      final res = await _apiService.getNotifications(_token!);
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _notifications = res['notifications'];
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_token == null) return;
    final ok = await _apiService.markAllNotificationsAsRead(_token!);
    if (ok) {
      setState(() {
        for (var notif in _notifications) {
          notif.isRead = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Semua notifikasi ditandai telah dibaca'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _markSingleRead(NotificationModel notif) async {
    if (_token == null || notif.isRead) return;
    final ok = await _apiService.markNotificationAsRead(_token!, notif.id);
    if (ok) {
      setState(() {
        notif.isRead = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppTheme.darkSurface.withValues(alpha: 0.90)
                  : Colors.white.withValues(alpha: 0.90),
              shape: BoxShape.circle,
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: Icon(Icons.done_all_rounded, size: 16, color: context.brandGreenBright),
                label: Text(
                  'Baca Semua',
                  style: TextStyle(
                    color: context.brandGreenBright,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: context.isDark ? 0.08 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: context.isDark ? 0.05 : 0.08),
              ),
            ),
          ),

          Column(
            children: [
              const OfflineStatusBanner(),
              Expanded(
                child: _isLoading
                    ? const NotificationListShimmerSkeleton()
                    : _notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: context.tahuTagBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.tahuTagBorder, width: 1.2),
                                    ),
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      size: 40,
                                      color: context.brandGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum Ada Notifikasi',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pemberitahuan terkait status pesanan akan masuk di sini.',
                                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: context.brandGreen,
                            onRefresh: _loadNotifications,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              itemCount: _notifications.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                return _buildNotificationCard(notif);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final bool isRead = notif.isRead;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _markSingleRead(notif),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRead
                    ? context.cardBg
                    : (context.isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                        : const Color(0xFFF0FDF4).withValues(alpha: 0.94)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRead
                      ? context.border
                      : context.brandGreen.withValues(alpha: 0.55),
                  width: isRead ? 1 : 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRead
                        ? Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.02)
                        : context.brandGreen.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isRead
                          ? (context.isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade100)
                          : context.tahuTagBg,
                      shape: BoxShape.circle,
                      border: isRead ? null : Border.all(color: context.tahuTagBorder),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: isRead ? context.textMuted : context.brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 14,
                                  color: isRead
                                      ? context.textPrimary
                                      : context.brandGreenBright,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: context.brandGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.pesan,
                          style: TextStyle(
                            fontSize: 12,
                            color: isRead ? context.textSecondary : context.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notif.timestamp ?? notif.createdAt ?? 'Baru saja',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRead ? context.textMuted : context.brandGreen,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
