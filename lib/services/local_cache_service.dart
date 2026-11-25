import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan cache lokal ringan berbasis SharedPreferences agar EcoTahu
/// tetap bisa dibuka & menampilkan katalog, resep, edukasi, pesanan,
/// profil, dan ringkasan admin saat pengguna sedang offline.
class LocalCacheService {
  static const String _prefix = 'eco_cache_v1_';

  static const String keyProducts = 'products';
  static const String keyLimbah = 'limbah';
  static const String keyRecipes = 'recipes';
  static const String keyArticles = 'articles';
  static const String keyToko = 'toko';
  static const String keyUserProfile = 'user_profile';
  static const String keyOrders = 'orders';
  static const String keyNotifications = 'notifications';
  static const String keyAdminOverview = 'admin_overview';

  static Future<void> saveJson(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      });
      await prefs.setString('$_prefix$key', payload);
    } catch (_) {}
  }

  static Future<dynamic> readJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> getLastUpdated(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['ts'] is int) {
        return DateTime.fromMillisecondsSinceEpoch(decoded['ts'] as int);
      }
    } catch (_) {}
    return null;
  }

  /// Hapus cache yang bersifat privat per akun saat logout.
  static Future<void> clearUserPrivateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in [
        keyUserProfile,
        keyOrders,
        keyNotifications,
        keyAdminOverview,
      ]) {
        await prefs.remove('$_prefix$k');
      }
    } catch (_) {}
  }
}
