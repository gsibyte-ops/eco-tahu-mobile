import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan token autentikasi terenkripsi menggunakan Android Keystore (AES-256).
/// Secara otomatis memigrasikan token lama dari SharedPreferences plaintext dan menghapus salinan plaintext-nya.
class SecureStorageService {
  static const String _tokenKey = 'auth_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }

    try {
      final secureToken = await _storage.read(key: _tokenKey);
      if (secureToken != null && secureToken.trim().isNotEmpty) {
        return secureToken;
      }

      // Migrasi satu kali dari SharedPreferences plaintext (jika ada sesi lama)
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        await _storage.write(key: _tokenKey, value: legacyToken);
        await prefs.remove(_tokenKey);
        return legacyToken;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await prefs.setString(_tokenKey, token);
      return;
    }

    try {
      await _storage.write(key: _tokenKey, value: token);
      // Pastikan tidak ada salinan plaintext tertinggal di SharedPreferences
      if (prefs.containsKey(_tokenKey)) {
        await prefs.remove(_tokenKey);
      }
    } catch (_) {
      // Fallback hanya jika Keystore perangkat bermasalah
      await prefs.setString(_tokenKey, token);
    }
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    if (!kIsWeb) {
      try {
        await _storage.delete(key: _tokenKey);
      } catch (_) {}
    }
  }
}
