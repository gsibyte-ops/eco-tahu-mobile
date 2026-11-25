import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_skeletons.dart';
import 'article_detail_screen.dart';
import '../services/secure_storage_service.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  List<Article> _articles = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    try {
      final token = await SecureStorageService.readToken();
      final articles = await ApiService().getArticles(token);
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Article> get _filteredArticles {
    if (_searchQuery.isEmpty) {
      return _articles;
    }
    return _articles.where((article) {
      return article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: context.isDark ? 0.06 : 0.12),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: context.isDark ? 0.04 : 0.08),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF059669),
              onRefresh: _fetchArticles,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF059669), size: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Edukasi & Wawasan',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kenali manfaat tahu & kelestarian lingkungan',
                              style: TextStyle(color: context.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Glass Search Capsule
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: TextStyle(fontSize: 14, color: context.textPrimary),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Cari topik edukasi, resep, atau tips...',
                              hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: context.brandGreen, size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel_rounded, color: context.textMuted, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Article List / States
                    if (_isLoading)
                      const ContentCardListShimmerSkeleton()
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                              const SizedBox(height: 10),
                              Text('Gagal memuat: $_errorMessage', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchArticles,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filteredArticles.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.menu_book_rounded, size: 36, color: Color(0xFF059669)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Artikel tidak ditemukan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba kata kunci lain atau periksa koneksi internet.',
                                style: TextStyle(color: context.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredArticles.length,
                        itemBuilder: (context, index) {
                          final article = _filteredArticles[index];
                          return _buildArticleCard(context, article);
                        },
                      ),

                    // Bottom padding for floating navigation dock
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
                );
                if (result is Map && result['id'] == article.id && mounted) {
                  setState(() {
                    final idx = _articles.indexWhere((a) => a.id == article.id);
                    if (idx != -1) {
                      _articles[idx] = _articles[idx].copyWith(
                        isLiked: result['is_liked'] == true,
                        likesCount: result['likes_count'] ?? _articles[idx].likesCount,
                      );
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
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
                    // Article Image with Gradient Overlay & Category Pill
                    Stack(
                      children: [
                        EcoCachedImage(
                          imageUrl: article.displayImageUrl,
                          width: double.infinity,
                          height: 185,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          fallbackIcon: article.mediaType == 'video'
                              ? Icons.play_circle_filled_rounded
                              : Icons.article_rounded,
                          fallbackColor: const Color(0xFF059669),
                          fallbackBgColor: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFE8F5E9),
                        ),
                        // Dark soft gradient bottom of image
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Category Pill floating
                        Positioned(
                          top: 14,
                          left: 14,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco_rounded, color: Color(0xFF34D399), size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      article.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (article.mediaType == 'youtube' || article.mediaType == 'video')
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: article.mediaType == 'youtube'
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    article.mediaType == 'youtube'
                                        ? Icons.play_arrow_rounded
                                        : Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    article.mediaType == 'youtube' ? 'YouTube' : 'Video',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Article Content
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 13, color: context.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                formatDate(article.date),
                                style: TextStyle(fontSize: 12, color: context.textMuted),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.schedule_rounded, size: 13, color: context.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '3 mnt baca',
                                style: TextStyle(fontSize: 12, color: context.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Baca Selengkapnya',
                                    style: TextStyle(
                                      color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669), size: 15),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    article.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 16,
                                    color: article.isLiked ? Colors.redAccent : context.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${article.likesCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: article.isLiked ? Colors.redAccent : context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
