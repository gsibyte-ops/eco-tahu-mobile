class MediaValidator {
  static const List<String> allowedImageExts = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedVideoExts = ['mp4', 'mov', 'webm'];

  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxVideoBytes = 20 * 1024 * 1024;

  static String _ext(String fileName) {
    final parts = fileName.trim().toLowerCase().split('.');
    return parts.length > 1 ? parts.last : '';
  }

  static bool isAllowedImage(String fileName) {
    return allowedImageExts.contains(_ext(fileName));
  }

  static bool isAllowedVideo(String fileName) {
    return allowedVideoExts.contains(_ext(fileName));
  }

  static bool isAllowedPhotoOrVideo(String fileName) {
    return isAllowedImage(fileName) || isAllowedVideo(fileName);
  }

  static String? validateImageFile(
    String fileName,
    int byteLength, {
    int maxBytes = 2 * 1024 * 1024,
  }) {
    if (!isAllowedImage(fileName)) {
      return 'Hanya file foto (JPG, JPEG, PNG, WEBP) yang diperbolehkan.';
    }
    if (byteLength <= 0) {
      return 'File foto kosong atau rusak.';
    }
    if (byteLength > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'Ukuran foto maksimal ${maxMb}MB.';
    }
    return null;
  }

  static String? validateVideoFile(
    String fileName,
    int byteLength, {
    int maxBytes = maxVideoBytes,
  }) {
    if (!isAllowedVideo(fileName)) {
      return 'Hanya file video (MP4, MOV, WEBM) yang diperbolehkan.';
    }
    if (byteLength <= 0) {
      return 'File video kosong atau rusak.';
    }
    if (byteLength > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'Ukuran video maksimal ${maxMb}MB.';
    }
    return null;
  }

  /// Extracts an 11-character YouTube video ID ONLY from official youtube.com / youtu.be URLs.
  static String? extractYoutubeId(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    const allowedHosts = ['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'];
    if (!allowedHosts.contains(host)) return null;

    if (host == 'youtu.be') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(segments.first)) {
        return segments.first;
      }
      return null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && (segments[0] == 'shorts' || segments[0] == 'embed')) {
      if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(segments[1])) {
        return segments[1];
      }
    }

    final v = uri.queryParameters['v'];
    if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) {
      return v;
    }

    return null;
  }

  static String? youtubeThumbnailUrl(String? url) {
    final id = extractYoutubeId(url);
    return id != null ? 'https://img.youtube.com/vi/$id/hqdefault.jpg' : null;
  }
}
