import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_guard.dart';
import '../widgets/media_preview_widgets.dart';
import '../services/secure_storage_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late bool _isLiked;
  late int _likesCount;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.article.isLiked;
    _likesCount = widget.article.likesCount;
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _popWithResult() {
    Navigator.pop(context, {
      'id': widget.article.id,
      'is_liked': _isLiked,
      'likes_count': _likesCount,
    });
  }

  Future<void> _handleToggleLike() async {
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'menyukai artikel edukasi',
    );
    if (!canProceed || !mounted || _isLiking) return;

    final prevLiked = _isLiked;
    final prevCount = _likesCount;

    setState(() {
      _isLiking = true;
      _isLiked = !prevLiked;
      _likesCount = (prevCount + (_isLiked ? 1 : -1)).clamp(0, 9999999);
    });

    final token = (await SecureStorageService.readToken()) ?? '';
    final res = await ApiService().toggleArticleLike(token, widget.article.id);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _isLiking = false;
        _isLiked = res['liked'] == true;
        _likesCount = res['likes_count'] ?? _likesCount;
      });
    } else {
      setState(() {
        _isLiking = false;
        _isLiked = prevLiked;
        _likesCount = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal memperbarui status suka'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showShareSheet() {
    final shareLink = widget.article.shareUrl;
    final shareText = '${widget.article.title}\n\nBaca selengkapnya di EcoTahu:\n$shareLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bagikan Artikel Edukasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.article.title,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_rounded, color: Color(0xFF059669)),
                  ),
                  title: Text('Bagikan ke WhatsApp', style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text('Kirim langsung ke kontak atau grup WA', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: Text('Salin Link Artikel', style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text(shareLink, style: TextStyle(fontSize: 11, color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Link artikel berhasil disalin!'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final heroImage = article.displayImageUrl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _popWithResult();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Stack(
          children: [
            // Background ambient glows
            Positioned(
              top: 240,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: context.isDark ? 0.06 : 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF059669).withValues(alpha: context.isDark ? 0.04 : 0.08),
                ),
              ),
            ),

            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Edge-to-edge Hero Header
                SliverAppBar(
                  expandedHeight: 270,
                  pinned: true,
                  backgroundColor: context.scaffoldBg,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.isDark ? AppTheme.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: context.border),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
                            onPressed: _popWithResult,
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.isDark ? AppTheme.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: context.border),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.share_outlined, size: 20, color: context.textPrimary),
                              onPressed: _showShareSheet,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: GestureDetector(
                      onTap: () {
                        if (article.mediaType == 'image' && article.imageUrl.isNotEmpty) {
                          FullscreenImageViewer.show(context, article.imageUrl);
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            heroImage,
                            cacheWidth: 1080,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFE8F5E9),
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: context.isDark 
                                      ? [AppTheme.darkSurfaceElevated, AppTheme.darkSurface]
                                      : [const Color(0xFFE8F5E9), const Color(0xFFD1FAE5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  article.mediaType == 'video'
                                      ? Icons.play_circle_filled_rounded
                                      : Icons.newspaper_rounded,
                                  size: 64,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                  context.scaffoldBg,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Article Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: context.border, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: context.isDark
                                                ? AppTheme.emeraldLight.withValues(alpha: 0.3)
                                                : const Color(0xFF10B981).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.eco_rounded, size: 13, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669)),
                                            const SizedBox(width: 4),
                                            Text(
                                              article.category,
                                              style: TextStyle(
                                                color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded, size: 12, color: context.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDate(article.date),
                                            style: TextStyle(fontSize: 12, color: context.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    article.title,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Oleh ${article.authorName}',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video / YouTube Player Card (when applicable)
                        if (article.mediaType == 'youtube' && article.youtubeUrl.isNotEmpty) ...[
                          YoutubeCardPreview(youtubeUrl: article.youtubeUrl, height: 210),
                          const SizedBox(height: 16),
                        ] else if (article.mediaType == 'video' && article.videoUrl.isNotEmpty) ...[
                          InlineVideoPlayer(videoUrl: article.videoUrl, height: 215),
                          const SizedBox(height: 16),
                        ],

                        // Like & Share Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.border, width: 1.1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _handleToggleLike,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isLiked
                                          ? Colors.redAccent.withValues(alpha: 0.14)
                                          : context.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isLiked
                                            ? Colors.redAccent.withValues(alpha: 0.5)
                                            : context.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 19,
                                          color: _isLiked ? Colors.redAccent : context.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isLiked ? 'Disukai ($_likesCount)' : 'Sukai ($_likesCount)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _isLiked ? Colors.redAccent : context.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showShareSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.share_rounded,
                                          size: 18,
                                          color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Bagikan',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Article Content Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: context.border, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: context.textPrimary,
                                      height: 1.75,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Zero-Waste Quote Banner inside Article
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.isDark ? AppTheme.emeraldDarkSoft.withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.format_quote_rounded, color: context.brandGreen, size: 28),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mendukung Gaya Hidup Zero Waste',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: context.brandGreenBright,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Setiap produk ampas tahu yang dimanfaatkan membantu menjaga kebersihan lingkungan Jember dan mengurangi limbah organik.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.textSecondary,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
