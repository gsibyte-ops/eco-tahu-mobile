class AppConfig {
  /// Default untuk dev lokal; saat build APK production cukup kirim:
  /// flutter build apk --release --dart-define=API_HOST=https://domain-kamu.com
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://eco-tahu-production.up.railway.app',
  );
  static const String apiBaseUrl = '$host/api';

  static String fileUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return '';
    String url = rawPath.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final loopback = RegExp(r'^http://127\.0\.0\.1:8000');
      if (loopback.hasMatch(url)) {
        url = url.replaceFirst(loopback, host);
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
