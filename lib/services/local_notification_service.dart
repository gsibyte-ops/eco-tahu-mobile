import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../screens/notification_screen.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

/// Layanan Push Notifikasi Lokal (Android System Tray) yang terhubung langsung
/// dengan endpoint `/api/notifications` di backend Laravel EcoTahu.
/// Setiap notifikasi baru (pesanan masuk, pembayaran diverifikasi, pesanan dikirim,
/// refund diproses, dll.) akan otomatis muncul sebagai notifikasi HP yang identik
/// dengan isi notifikasi di dalam aplikasi.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  static const String _channelId = 'ecotahu_updates_channel';
  static const String _channelName = 'Notifikasi EcoTahu';
  static const String _channelDesc = 'Pembaruan status pesanan, pembayaran, dan info EcoTahu';
  static const String _notifiedIdsKey = 'ecotahu_notified_ids_v1';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _pollTimer;
  bool _initialized = false;
  bool _isPolling = false;

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;
    if (kIsWeb || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _openNotificationsScreen();
      },
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  /// Meminta izin notifikasi Android 13+ (POST_NOTIFICATIONS) secara halus.
  Future<void> requestPermission() async {
    if (kIsWeb || !_initialized) return;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Mulai sinkronisasi notifikasi berkala saat aplikasi aktif.
  void startPolling({Duration interval = const Duration(seconds: 25)}) {
    if (kIsWeb) return;
    _pollTimer?.cancel();
    // Cek segera sekali, lalu periodik
    pollNow();
    _pollTimer = Timer.periodic(interval, (_) => pollNow());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Cek notifikasi terbaru dari server `/api/notifications` dan tampilkan
  /// push notification ke HP untuk notifikasi belum dibaca yang belum pernah dipush.
  Future<void> pollNow({bool suppressFirstBatch = false}) async {
    if (kIsWeb || !_initialized || _isPolling) return;
    _isPolling = true;
    try {
      final token = await SecureStorageService.readToken();
      if (token == null || token.trim().isEmpty) return;

      final res = await ApiService().getNotifications(token, useCacheOnError: false);
      if (res['success'] != true) return;

      final List<NotificationModel> list =
          (res['notifications'] as List<NotificationModel>?) ?? const [];
      if (list.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final rawKnown = prefs.getString(_notifiedIdsKey);
      final Set<String> knownIds = rawKnown != null
          ? Set<String>.from((jsonDecode(rawKnown) as List).map((e) => e.toString()))
          : <String>{};

      final bool isFirstEverSync = rawKnown == null;
      final List<NotificationModel> toPush = [];

      for (final notif in list) {
        if (notif.id.isEmpty) continue;
        if (!knownIds.contains(notif.id)) {
          knownIds.add(notif.id);
          if (!notif.isRead) {
            toPush.add(notif);
          }
        }
      }

      // Batasi riwayat ID tersimpan agar ringan (maks 200 ID terakhir)
      final trimmed = knownIds.length > 200
          ? knownIds.skip(knownIds.length - 200).toList()
          : knownIds.toList();
      await prefs.setString(_notifiedIdsKey, jsonEncode(trimmed));

      if (suppressFirstBatch && isFirstEverSync) {
        return;
      }

      // Saat sinkronisasi pertama, tampilkan maksimal 2 notifikasi terbaru yang belum dibaca
      final displayList = isFirstEverSync ? toPush.take(2).toList() : toPush.take(5).toList();
      for (final notif in displayList) {
        await showNotification(
          id: notif.id.hashCode & 0x7FFFFFFF,
          title: notif.title,
          body: notif.pesan,
          payload: notif.id,
        );
      }
    } catch (_) {
      // Abaikan diam-diam saat offline
    } finally {
      _isPolling = false;
    }
  }

  /// Menampilkan satu push notification langsung ke status bar Android.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF059669),
        styleInformation: BigTextStyleInformation(''),
      );
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  /// Reset catatan ID notifikasi saat logout agar akun berikutnya tidak bentrok.
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notifiedIdsKey);
    } catch (_) {}
  }

  void _openNotificationsScreen() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }
}
