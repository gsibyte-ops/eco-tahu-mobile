import '../config/app_config.dart';

class Recipe {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String ingredients;
  final List<String> ingredientsList;
  final String steps;
  final List<String> stepsList;
  final int durationMinutes;
  final int servings;
  final String difficulty; // 'mudah', 'sedang', 'sulit'
  final String imageUrl;
  final String mediaType; // 'image', 'video', 'youtube'
  final String videoUrl;
  final String youtubeUrl;
  final String youtubeThumbnailUrl;
  final String shareUrl;
  final String authorName;
  final int likesCount;
  final bool isLiked;
  final DateTime date;

  Recipe({
    required this.id,
    required this.title,
    this.slug = '',
    this.description = '',
    required this.ingredients,
    this.ingredientsList = const [],
    required this.steps,
    this.stepsList = const [],
    this.durationMinutes = 15,
    this.servings = 2,
    this.difficulty = 'mudah',
    required this.imageUrl,
    this.mediaType = 'image',
    this.videoUrl = '',
    this.youtubeUrl = '',
    this.youtubeThumbnailUrl = '',
    this.shareUrl = '',
    this.authorName = 'Admin EcoTahu',
    this.likesCount = 0,
    this.isLiked = false,
    required this.date,
  });

  String get displayImageUrl => imageUrl.isNotEmpty ? imageUrl : youtubeThumbnailUrl;

  String get difficultyLabel {
    switch (difficulty.toLowerCase()) {
      case 'sedang':
        return 'Sedang';
      case 'sulit':
        return 'Sulit';
      case 'mudah':
      default:
        return 'Mudah';
    }
  }

  Recipe copyWith({
    int? likesCount,
    bool? isLiked,
  }) {
    return Recipe(
      id: id,
      title: title,
      slug: slug,
      description: description,
      ingredients: ingredients,
      ingredientsList: ingredientsList,
      steps: steps,
      stepsList: stepsList,
      durationMinutes: durationMinutes,
      servings: servings,
      difficulty: difficulty,
      imageUrl: imageUrl,
      mediaType: mediaType,
      videoUrl: videoUrl,
      youtubeUrl: youtubeUrl,
      youtubeThumbnailUrl: youtubeThumbnailUrl,
      shareUrl: shareUrl,
      authorName: authorName,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      date: date,
    );
  }

  static List<String> _parseLines(dynamic listField, String fallbackText) {
    if (listField is List) {
      final parsed = listField
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return fallbackText
        .split(RegExp(r'\r\n|\r|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final String thumbUrl = AppConfig.fileUrl(
      (json['thumbnail_url']?.toString().trim().isNotEmpty == true)
          ? json['thumbnail_url']?.toString()
          : json['thumbnail']?.toString(),
    );

    final String vidUrl = AppConfig.fileUrl(json['video_url']?.toString());
    final String ytUrl = json['youtube_url']?.toString().trim() ?? '';
    final String ytThumb = json['youtube_thumbnail_url']?.toString().trim() ?? '';
    final String slugStr = json['slug']?.toString() ?? '';
    final String rawShare = json['share_url']?.toString().trim() ?? '';
    final String resolvedShare = rawShare.isNotEmpty
        ? rawShare
        : (slugStr.isNotEmpty ? '${AppConfig.host}/resep/$slugStr' : '${AppConfig.host}/resep');

    final String rawBahan = json['bahan']?.toString() ?? '';
    final String rawLangkah = json['langkah']?.toString() ?? '';
    final dynamic rawDate = json['published_at'] ?? json['created_at'];

    return Recipe(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['judul']?.toString() ?? 'Tanpa Judul',
      slug: slugStr,
      description: json['deskripsi']?.toString() ?? '',
      ingredients: rawBahan,
      ingredientsList: _parseLines(json['bahan_list'], rawBahan),
      steps: rawLangkah,
      stepsList: _parseLines(json['langkah_list'], rawLangkah),
      durationMinutes: int.tryParse(json['durasi_menit']?.toString() ?? '15') ?? 15,
      servings: int.tryParse(json['porsi']?.toString() ?? '2') ?? 2,
      difficulty: (json['tingkat_kesulitan']?.toString() ?? 'mudah').toLowerCase(),
      imageUrl: thumbUrl,
      mediaType: json['media_type']?.toString() ?? 'image',
      videoUrl: vidUrl,
      youtubeUrl: ytUrl,
      youtubeThumbnailUrl: ytThumb,
      shareUrl: resolvedShare,
      authorName: json['author_name']?.toString() ?? 'Admin EcoTahu',
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      date: rawDate != null ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}
