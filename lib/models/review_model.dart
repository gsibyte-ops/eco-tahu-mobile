import '../config/app_config.dart';

class ReviewModel {
  final int id;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String? komentar;
  final String? mediaUrl;
  final String? mediaType;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.komentar,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['user_avatar']?.toString();
    final rawMedia = json['media_url']?.toString();
    return ReviewModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? 'Pelanggan',
      userAvatar: (rawAvatar != null && rawAvatar.isNotEmpty) ? AppConfig.fileUrl(rawAvatar) : null,
      rating: int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      komentar: json['komentar'],
      mediaUrl: (rawMedia != null && rawMedia.isNotEmpty) ? AppConfig.fileUrl(rawMedia) : null,
      mediaType: json['media_type']?.toString(),
      createdAt: json['created_at'] ?? '',
    );
  }
}
