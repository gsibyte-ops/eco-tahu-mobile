import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/limbah.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/connectivity_provider.dart';
import 'cart_screen.dart';
import '../widgets/auth_guard.dart';
import '../widgets/media_preview_widgets.dart';
import '../widgets/shimmer_skeletons.dart';
import '../theme/app_theme.dart';

class LimbahDetailScreen extends StatefulWidget {
  final Limbah limbah;

  const LimbahDetailScreen({super.key, required this.limbah});

  @override
  State<LimbahDetailScreen> createState() => _LimbahDetailScreenState();
}

class _LimbahDetailScreenState extends State<LimbahDetailScreen> {
  final ApiService _apiService = ApiService();
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final list = await _apiService.getReviews('limbah', widget.limbah.id);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final limbah = widget.limbah;
    final int reviewsCount = _reviews.isNotEmpty ? _reviews.length : limbah.reviewsCount;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _buildCircleGlassButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final totalItems = cart.items.fold(0, (sum, item) => sum + item.quantity);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.isDark ? AppTheme.darkSurface.withOpacity(0.85) : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: context.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.shopping_bag_outlined, color: context.textPrimary, size: 20),
                        ),
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO IMAGE WITH CURVE
                Container(
                  width: double.infinity,
                  height: 330,
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                    child: limbah.imageUrl.isNotEmpty
                        ? Image.network(
                            limbah.imageUrl,
                            width: double.infinity,
                            height: 330,
                            cacheWidth: 1080,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: context.limbahTagBg,
                              child: Center(child: Icon(Icons.recycling_rounded, size: 72, color: context.brandAmber)),
                            ),
                          )
                        : Container(
                            color: context.limbahTagBg,
                            child: Center(child: Icon(Icons.recycling_rounded, size: 72, color: context.brandAmber)),
                          ),
                  ),
                ),

                // 2. LIMBAH INFO CONTAINER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Kategori & Status Stok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.limbahTagBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.limbahTagBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.recycling_rounded, size: 14, color: context.limbahTagText),
                                const SizedBox(width: 4),
                                Text(
                                  'Ampas Tahu Zero-Waste',
                                  style: TextStyle(
                                    color: context.limbahTagText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: limbah.stok > 0 
                                  ? (context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4)) 
                                  : (context.isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEF2F2)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: limbah.stok > 0 
                                    ? (context.isDark ? AppTheme.emeraldLight.withOpacity(0.4) : const Color(0xFF86EFAC)) 
                                    : (context.isDark ? Colors.red.shade900 : const Color(0xFFFECACA)),
                              ),
                            ),
                            child: Text(
                              limbah.stok > 0 ? 'Tersedia: ${limbah.stok} ${limbah.satuan}' : 'Stok Habis',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: limbah.stok > 0 
                                    ? (context.isDark ? AppTheme.emeraldLight : const Color(0xFF15803D)) 
                                    : (context.isDark ? Colors.red.shade400 : const Color(0xFFDC2626)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nama Limbah
                      Text(
                        limbah.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating & Ulasan
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final int starNo = index + 1;
                            final bool isFilled = reviewsCount > 0 && starNo <= limbah.rating.round();
                            return Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: isFilled ? const Color(0xFFFBBF24) : (context.isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            reviewsCount > 0
                                ? '${limbah.rating.toStringAsFixed(1)} ($reviewsCount ulasan)'
                                : 'Belum ada ulasan',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Deskripsi Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Text(
                                  'Deskripsi & Manfaat',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              limbah.description.isNotEmpty
                                  ? limbah.description
                                  : 'Ampas tahu segar berprotein tinggi yang dapat diolah untuk pakan ternak bernutrisi atau pupuk organik ramah lingkungan.',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SECTION ULASAN PEMBELI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ulasan Pembeli',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_reviews.length}',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final canProceed = await AuthGuard.requireAuth(
                                context,
                                actionMessage: 'menulis ulasan dan memberikan rating',
                              );
                              if (!canProceed || !context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ulasan dapat diberikan setelah pesanan berstatus Selesai di menu Pesanan Saya.'),
                                  backgroundColor: Color(0xFFD97706),
                                ),
                              );
                            },
                            icon: Icon(Icons.rate_review_outlined, size: 15, color: context.brandAmber),
                            label: Text(
                              'Tulis Ulasan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.brandAmber,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: context.limbahTagBg,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _isLoadingReviews
                          ? const ReviewsShimmerSkeleton()
                          : _reviews.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.watch<ConnectivityProvider>().isOffline
                                          ? 'Ulasan & komentar tidak dapat dimuat saat mode offline.'
                                          : 'Belum ada ulasan untuk produk ini.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: context.textMuted, fontSize: 13),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _reviews.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final rev = _reviews[index];
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: context.cardBg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: context.border, width: 1.1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.15),
                                                    child: (rev.userAvatar != null && rev.userAvatar!.isNotEmpty)
                                                        ? ClipOval(
                                                            child: Image.network(
                                                              rev.userAvatar!,
                                                              width: 28,
                                                              height: 28,
                                                              cacheWidth: 400,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => Text(
                                                                rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'U',
                                                                style: const TextStyle(
                                                                  color: Color(0xFFD97706),
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'U',
                                                            style: const TextStyle(
                                                              color: Color(0xFFD97706),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    rev.userName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                      color: context.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                rev.createdAt,
                                                style: TextStyle(color: context.textMuted, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIdx) => Icon(
                                                Icons.star_rounded,
                                                size: 15,
                                                color: starIdx < rev.rating
                                                    ? const Color(0xFFFBBF24)
                                                    : (context.isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                                              ),
                                            ),
                                          ),
                                          if (rev.komentar != null && rev.komentar!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              rev.komentar!,
                                              style: TextStyle(fontSize: 12.5, color: context.textSecondary, height: 1.35),
                                            ),
                                          ],
                                          if (rev.mediaUrl != null && rev.mediaUrl!.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            if (rev.mediaType == 'video')
                                              InlineVideoPlayer(videoUrl: rev.mediaUrl!, height: 185)
                                            else
                                              GestureDetector(
                                                onTap: () => FullscreenImageViewer.show(context, rev.mediaUrl!),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Image.network(
                                                        rev.mediaUrl!,
                                                        height: 140,
                                                        width: 140,
                                                        cacheWidth: 600,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Container(
                                                          height: 140,
                                                          width: 140,
                                                          color: context.surface,
                                                          child: Icon(Icons.broken_image_rounded, color: context.textMuted),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 6,
                                                      right: 6,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withValues(alpha: 0.6),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 14),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. STICKY FROSTED GLASS BOTTOM BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: context.surface.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(color: context.border, width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Kolom Harga
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga',
                              style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              limbah.price,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.brandAmber,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol Beli / Tambah
                      ElevatedButton.icon(
                        onPressed: () async {
                          final canProceed = await AuthGuard.requireAuth(
                            context,
                            actionMessage: 'menambahkan limbah ke keranjang belanja',
                          );
                          if (!canProceed || !context.mounted) return;

                          Provider.of<CartProvider>(context, listen: false).addToCart(limbah.toProduct());
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${limbah.name} masuk ke keranjang!'),
                              backgroundColor: const Color(0xFFD97706),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text(
                          'Beli Sekarang',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                          elevation: 3,
                          shadowColor: const Color(0xFFD97706).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.isDark ? AppTheme.darkSurface.withOpacity(0.85) : Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: context.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: context.textPrimary, size: 20),
        ),
      ),
    );
  }
}
