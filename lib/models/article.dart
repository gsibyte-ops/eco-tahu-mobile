import '../config/app_config.dart';

class Article {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime date;
  final String mediaType; // 'image', 'video', 'youtube'
  final String videoUrl;
  final String youtubeUrl;
  final String youtubeThumbnailUrl;
  final String shareUrl;
  final String authorName;
  final int likesCount;
  final bool isLiked;

  Article({
    required this.id,
    required this.title,
    this.slug = '',
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.date,
    this.mediaType = 'image',
    this.videoUrl = '',
    this.youtubeUrl = '',
    this.youtubeThumbnailUrl = '',
    this.shareUrl = '',
    this.authorName = 'Admin EcoTahu',
    this.likesCount = 0,
    this.isLiked = false,
  });

  String get displayImageUrl => imageUrl.isNotEmpty ? imageUrl : youtubeThumbnailUrl;

  Article copyWith({
    int? likesCount,
    bool? isLiked,
  }) {
    return Article(
      id: id,
      title: title,
      slug: slug,
      content: content,
      imageUrl: imageUrl,
      category: category,
      date: date,
      mediaType: mediaType,
      videoUrl: videoUrl,
      youtubeUrl: youtubeUrl,
      youtubeThumbnailUrl: youtubeThumbnailUrl,
      shareUrl: shareUrl,
      authorName: authorName,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    final String thumbUrl = AppConfig.fileUrl(
      (json['thumbnail_url']?.toString().trim().isNotEmpty == true)
          ? json['thumbnail_url']?.toString()
          : (json['thumbnail'] ?? json['gambar'])?.toString(),
    );

    final String vidUrl = AppConfig.fileUrl(json['video_url']?.toString());
    final String ytUrl = json['youtube_url']?.toString().trim() ?? '';
    final String ytThumb = json['youtube_thumbnail_url']?.toString().trim() ?? '';
    final String slugStr = json['slug']?.toString() ?? '';
    final String rawShare = json['share_url']?.toString().trim() ?? '';
    final String resolvedShare = rawShare.isNotEmpty
        ? rawShare
        : (slugStr.isNotEmpty ? '${AppConfig.host}/edukasi/$slugStr' : '${AppConfig.host}/edukasi');

    final dynamic rawDate = json['published_at'] ?? json['created_at'];

    return Article(
      id: json['id'] ?? 0,
      title: json['judul'] ?? 'Tanpa Judul',
      slug: slugStr,
      content: json['konten'] ?? json['isi'] ?? '',
      imageUrl: thumbUrl,
      category: json['kategori'] ?? 'Edukasi Lingkungan',
      date: rawDate != null ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now()) : DateTime.now(),
      mediaType: json['media_type']?.toString() ?? 'image',
      videoUrl: vidUrl,
      youtubeUrl: ytUrl,
      youtubeThumbnailUrl: ytThumb,
      shareUrl: resolvedShare,
      authorName: json['author_name']?.toString() ?? 'Admin EcoTahu',
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
    );
  }
}
