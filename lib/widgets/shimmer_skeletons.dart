import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Base wrapper shimmer yang otomatis menyesuaikan Dark/Light Mode EcoTahu.
class EcoShimmer extends StatelessWidget {
  final Widget child;

  const EcoShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      period: const Duration(milliseconds: 1250),
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Gambar jaringan dengan cache disk offline + Shimmer placeholder saat memuat
/// + fallback icon rapi bila sedang offline dan gambar belum pernah di-cache.
class EcoCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBgColor;

  const EcoCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.eco_rounded,
    this.fallbackColor,
    this.fallbackBgColor,
  });

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: fallbackBgColor ?? context.tahuTagBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            fallbackIcon,
            size: (height != null && height! < 70) ? 24 : 34,
            color: fallbackColor ?? context.brandGreen,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imageUrl.trim().isEmpty) {
      content = _buildFallback(context);
    } else {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => EcoShimmer(
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}

/// 1. Skeleton untuk Halaman Beranda (HomeScreen)
class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const ShimmerBox(width: 44, height: 44, radius: 14),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 90, height: 12, radius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(width: 140, height: 16, radius: 6),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: const [
                    ShimmerBox(width: 38, height: 38, radius: 12),
                    SizedBox(width: 8),
                    ShimmerBox(width: 38, height: 38, radius: 12),
                    SizedBox(width: 8),
                    ShimmerBox(width: 38, height: 38, radius: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Search bar
            const ShimmerBox(width: double.infinity, height: 50, radius: 16),
            const SizedBox(height: 20),
            // Hero Banner
            const ShimmerBox(width: double.infinity, height: 158, radius: 22),
            const SizedBox(height: 22),
            // Quick category row
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 76, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 76, radius: 16)),
              ],
            ),
            const SizedBox(height: 16),
            // Resep quick banner
            const ShimmerBox(width: double.infinity, height: 68, radius: 18),
            const SizedBox(height: 24),
            // Section title
            const ShimmerBox(width: 150, height: 18, radius: 6),
            const SizedBox(height: 14),
            // 2-column Product Grid
            const _ProductGridShimmerItems(count: 4),
          ],
        ),
      ),
    );
  }
}

/// 2. Skeleton untuk Katalog Produk & Limbah (2-kolom)
class ProductGridShimmerSkeleton extends StatelessWidget {
  final bool includeSearchHeader;
  final int itemCount;

  const ProductGridShimmerSkeleton({
    super.key,
    this.includeSearchHeader = true,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (includeSearchHeader) ...[
              const ShimmerBox(width: double.infinity, height: 48, radius: 16),
              const SizedBox(height: 14),
              Row(
                children: const [
                  ShimmerBox(width: 76, height: 34, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 108, height: 34, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 118, height: 34, radius: 20),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _ProductGridShimmerItems(count: itemCount),
          ],
        ),
      ),
    );
  }
}

class _ProductGridShimmerItems extends StatelessWidget {
  final int count;
  const _ProductGridShimmerItems({required this.count});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(child: ShimmerBox(width: double.infinity, height: double.infinity, radius: 14)),
              SizedBox(height: 10),
              ShimmerBox(width: 110, height: 14, radius: 6),
              SizedBox(height: 6),
              ShimmerBox(width: 75, height: 12, radius: 6),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 70, height: 16, radius: 6),
                  ShimmerBox(width: 32, height: 32, radius: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 3. Skeleton untuk Daftar Kartu Artikel & Resep
class ContentCardListShimmerSkeleton extends StatelessWidget {
  final int count;

  const ContentCardListShimmerSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: Column(
        children: List.generate(count, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: double.infinity, height: 150, radius: 18),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 90, height: 18, radius: 10),
                      SizedBox(height: 10),
                      ShimmerBox(width: double.infinity, height: 16, radius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 210, height: 14, radius: 6),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 100, height: 12, radius: 6),
                          ShimmerBox(width: 64, height: 12, radius: 6),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// 4. Skeleton untuk Daftar Pesanan & Notifikasi
class OrderListShimmerSkeleton extends StatelessWidget {
  final int count;

  const OrderListShimmerSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 120, height: 14, radius: 6),
                    ShimmerBox(width: 74, height: 22, radius: 12),
                  ],
                ),
                SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 13, radius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 13, radius: 6),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 95, height: 16, radius: 6),
                    ShimmerBox(width: 88, height: 32, radius: 10),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 5. Skeleton untuk Daftar Notifikasi
class NotificationListShimmerSkeleton extends StatelessWidget {
  final int count;

  const NotificationListShimmerSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 42, height: 42, radius: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 160, height: 14, radius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: double.infinity, height: 12, radius: 6),
                      SizedBox(height: 5),
                      ShimmerBox(width: 190, height: 12, radius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 10, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 6. Skeleton untuk Dashboard Admin Overview
class AdminOverviewShimmerSkeleton extends StatelessWidget {
  const AdminOverviewShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 150, height: 18, radius: 6),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 118, radius: 18)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 118, radius: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 118, radius: 18)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 118, radius: 18)),
              ],
            ),
            const SizedBox(height: 18),
            const ShimmerBox(width: double.infinity, height: 68, radius: 18),
            const SizedBox(height: 22),
            const ShimmerBox(width: 180, height: 18, radius: 6),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 180, radius: 18),
            const SizedBox(height: 22),
            const ShimmerBox(width: double.infinity, height: 130, radius: 18),
          ],
        ),
      ),
    );
  }
}

/// 7. Skeleton untuk Profil Screen
class ProfileShimmerSkeleton extends StatelessWidget {
  const ProfileShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: const [
                  ShimmerBox(width: 82, height: 82, radius: 41),
                  SizedBox(height: 14),
                  ShimmerBox(width: 150, height: 18, radius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 190, height: 13, radius: 6),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ShimmerBox(width: double.infinity, height: 64, radius: 16),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 64, radius: 16),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 64, radius: 16),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 64, radius: 16),
          ],
        ),
      ),
    );
  }
}

/// 8. Skeleton kecil untuk ulasan/komentar di Detail Produk
class ReviewsShimmerSkeleton extends StatelessWidget {
  const ReviewsShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoShimmer(
      child: Column(
        children: List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    ShimmerBox(width: 32, height: 32, radius: 16),
                    SizedBox(width: 10),
                    ShimmerBox(width: 110, height: 13, radius: 6),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerBox(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 5),
                ShimmerBox(width: 160, height: 12, radius: 6),
              ],
            ),
          );
        }),
      ),
    );
  }
}
