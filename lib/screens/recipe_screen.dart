import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ecotahu_loader.dart';
import 'recipe_detail_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDifficulty = 'semua';

  bool _isLoading = true;
  List<Recipe> _recipes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final recipes = await ApiService().getRecipes(token);
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _errorMessage = null;
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

  List<Recipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      final matchesDiff = _selectedDifficulty == 'semua' ||
          recipe.difficulty.toLowerCase() == _selectedDifficulty;
      if (!matchesDiff) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return recipe.title.toLowerCase().contains(q) ||
          recipe.description.toLowerCase().contains(q) ||
          recipe.ingredients.toLowerCase().contains(q);
    }).toList();
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'sulit':
        return const Color(0xFFDC2626);
      case 'sedang':
        return const Color(0xFFD97706);
      case 'mudah':
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
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
                color: const Color(0xFFF59E0B).withValues(alpha: context.isDark ? 0.04 : 0.08),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF059669),
              onRefresh: _fetchRecipes,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (canPop) ...[
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.border),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.textPrimary),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: context.isDark
                                          ? AppTheme.emeraldDarkSoft
                                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF059669), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Resep Olahan Tahu',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kreasi menu lezat & sehat dari tahu organik EcoTahu',
                                style: TextStyle(color: context.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
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
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(fontSize: 14, color: context.textPrimary),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Cari nama resep atau bahan masakan...',
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
                    const SizedBox(height: 14),

                    // Difficulty Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDiffChip('semua', 'Semua'),
                          const SizedBox(width: 8),
                          _buildDiffChip('mudah', 'Mudah'),
                          const SizedBox(width: 8),
                          _buildDiffChip('sedang', 'Sedang'),
                          const SizedBox(width: 8),
                          _buildDiffChip('sulit', 'Sulit'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EcoTahuLoadingIndicator(),
                      )
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
                                onPressed: _fetchRecipes,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filteredRecipes.isEmpty)
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
                                child: const Icon(Icons.restaurant_menu_rounded, size: 36, color: Color(0xFF059669)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Resep tidak ditemukan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba kata kunci atau tingkat kesulitan lain.',
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
                        itemCount: _filteredRecipes.length,
                        itemBuilder: (context, index) => _buildRecipeCard(context, _filteredRecipes[index]),
                      ),

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

  Widget _buildDiffChip(String value, String label) {
    final selected = _selectedDifficulty == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.brandGreen : context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.brandGreen : context.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.brandGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final diffColor = _difficultyColor(recipe.difficulty);

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
                  MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
                );
                if (result is Map && result['id'] == recipe.id && mounted) {
                  setState(() {
                    final idx = _recipes.indexWhere((r) => r.id == recipe.id);
                    if (idx != -1) {
                      _recipes[idx] = _recipes[idx].copyWith(
                        isLiked: result['is_liked'] == true,
                        likesCount: result['likes_count'] ?? _recipes[idx].likesCount,
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
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          child: Image.network(
                            recipe.displayImageUrl,
                            width: double.infinity,
                            height: 185,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 185,
                                color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFE8F5E9),
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 185,
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
                                  size: 54,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              recipe.difficultyLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (recipe.mediaType == 'youtube' || recipe.mediaType == 'video')
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: recipe.mediaType == 'youtube'
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
                                    recipe.mediaType == 'youtube'
                                        ? Icons.play_arrow_rounded
                                        : Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.mediaType == 'youtube' ? 'YouTube' : 'Video',
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
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 13, color: context.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.durationMinutes} mnt',
                                style: TextStyle(fontSize: 12, color: context.textMuted),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.people_outline_rounded, size: 14, color: context.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.servings} porsi',
                                style: TextStyle(fontSize: 12, color: context.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (recipe.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              recipe.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                                height: 1.45,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lihat Resep',
                                    style: TextStyle(
                                      color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                    size: 15,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    recipe.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 16,
                                    color: recipe.isLiked ? Colors.redAccent : context.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe.likesCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: recipe.isLiked ? Colors.redAccent : context.textMuted,
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
