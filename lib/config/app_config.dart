class AppConfig {
  // Ganti 1 baris ini ke URL server / domain asli saat build APK production (mis. https://ecotahu.com)
  static const String host = 'http://localhost:8000';
  static const String apiBaseUrl = '$host/api';

  static String fileUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return '';
    String url = rawPath.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (host.contains('localhost') && url.contains('127.0.0.1:8000')) {
        url = url.replaceAll('http://127.0.0.1:8000', host);
      }
      return url;
    }

    String clean = url.replaceFirst('storage/', '').replaceFirst('public/', '');
    while (clean.startsWith('/')) {
      clean = clean.substring(1);
    }
    return '$host/files/$clean';
  }
}
