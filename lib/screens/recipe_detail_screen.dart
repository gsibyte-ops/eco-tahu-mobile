import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_guard.dart';
import '../widgets/media_preview_widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late bool _isLiked;
  late int _likesCount;
  bool _isLiking = false;
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _isLiked = widget.recipe.isLiked;
    _likesCount = widget.recipe.likesCount;
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _popWithResult() {
    Navigator.pop(context, {
      'id': widget.recipe.id,
      'is_liked': _isLiked,
      'likes_count': _likesCount,
    });
  }

  Future<void> _handleToggleLike() async {
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'menyukai resep olahan tahu',
    );
    if (!canProceed || !mounted || _isLiking) return;

    final prevLiked = _isLiked;
    final prevCount = _likesCount;

    setState(() {
      _isLiking = true;
      _isLiked = !prevLiked;
      _likesCount = (prevCount + (_isLiked ? 1 : -1)).clamp(0, 9999999);
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final res = await ApiService().toggleRecipeLike(token, widget.recipe.id);

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
    final shareLink = widget.recipe.shareUrl;
    final shareText = '${widget.recipe.title}\n\nCobain resep olahan tahu ini di EcoTahu:\n$shareLink';

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
                  'Bagikan Resep Olahan Tahu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.recipe.title,
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
                  subtitle: Text('Kirim resep ini ke keluarga atau teman', style: TextStyle(fontSize: 12, color: context.textSecondary)),
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
                  title: Text('Salin Link Resep', style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text(shareLink, style: TextStyle(fontSize: 11, color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Link resep berhasil disalin!'),
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
    final recipe = widget.recipe;
    final heroImage = recipe.displayImageUrl;
    final ingredients = recipe.ingredientsList;
    final steps = recipe.stepsList;

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
                  color: const Color(0xFFF59E0B).withValues(alpha: context.isDark ? 0.04 : 0.08),
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
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
                        if (recipe.mediaType == 'image' && recipe.imageUrl.isNotEmpty) {
                          FullscreenImageViewer.show(context, recipe.imageUrl);
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
                                  recipe.mediaType == 'video'
                                      ? Icons.play_circle_filled_rounded
                                      : Icons.restaurant_menu_rounded,
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

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card + 3 Metadata Strip
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
                                        child: Text(
                                          recipe.difficultyLabel,
                                          style: TextStyle(
                                            color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded, size: 12, color: context.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDate(recipe.date),
                                            style: TextStyle(fontSize: 12, color: context.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    recipe.title,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Oleh ${recipe.authorName}',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildMetaTile(context, Icons.schedule_rounded, 'Durasi', '${recipe.durationMinutes} mnt'),
                                      const SizedBox(width: 8),
                                      _buildMetaTile(context, Icons.people_outline_rounded, 'Porsi', '${recipe.servings} porsi'),
                                      const SizedBox(width: 8),
                                      _buildMetaTile(context, Icons.local_fire_department_rounded, 'Level', recipe.difficultyLabel),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video / YouTube Player Card
                        if (recipe.mediaType == 'youtube' && recipe.youtubeUrl.isNotEmpty) ...[
                          YoutubeCardPreview(youtubeUrl: recipe.youtubeUrl, height: 210),
                          const SizedBox(height: 16),
                        ] else if (recipe.mediaType == 'video' && recipe.videoUrl.isNotEmpty) ...[
                          InlineVideoPlayer(videoUrl: recipe.videoUrl, height: 215),
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

                        if (recipe.description.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: context.border, width: 1.1),
                            ),
                            child: Text(
                              recipe.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Interactive Ingredients Checklist
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: context.border, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Bahan-Bahan',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_checkedIngredients.length}/${ingredients.length} siap',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.brandGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(ingredients.length, (idx) {
                                final isChecked = _checkedIngredients.contains(idx);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (isChecked) {
                                        _checkedIngredients.remove(idx);
                                      } else {
                                        _checkedIngredients.add(idx);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: context.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isChecked
                                            ? context.brandGreen.withValues(alpha: 0.45)
                                            : context.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                          size: 20,
                                          color: isChecked ? context.brandGreen : context.textMuted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            ingredients[idx],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isChecked ? context.textMuted : context.textPrimary,
                                              decoration: isChecked ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Cooking Steps
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: context.border, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Langkah Memasak',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...List.generate(steps.length, (idx) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: context.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          ),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${idx + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          steps[idx],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: context.textPrimary,
                                            height: 1.55,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
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

  Widget _buildMetaTile(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: context.brandGreen),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: context.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
