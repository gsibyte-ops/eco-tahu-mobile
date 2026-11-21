class NotificationModel {
  final String id;
  final String title;
  final String pesan;
  final String? url;
  bool isRead;
  final String? readAt;
  final String? createdAt;
  final String? timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.pesan,
    this.url,
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Info Pesanan',
      pesan: json['pesan'] ?? '',
      url: json['url'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      createdAt: json['created_at'],
      timestamp: json['timestamp'],
    );
  }
}
