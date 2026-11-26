import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/limbah.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'limbah_detail_screen.dart';
import 'cart_screen.dart';
import '../widgets/auth_guard.dart';
import '../widgets/shimmer_skeletons.dart';

class LimbahScreen extends StatefulWidget {
  const LimbahScreen({super.key});

  @override
  State<LimbahScreen> createState() => _LimbahScreenState();
}

class _LimbahScreenState extends State<LimbahScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  bool _isLoading = true;
  List<Limbah> _limbahList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLimbah();
  }

  Future<void> _fetchLimbah() async {
    try {
      final limbah = await ApiService().getLimbah();
      if (mounted) {
        setState(() {
          _limbahList = limbah;
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

  List<Limbah> get _filteredLimbah {
    if (_searchQuery.isEmpty) return _limbahList;
    return _limbahList
        .where((l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Olahan Ampas Tahu',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.textPrimary,
            letterSpacing: -0.3,
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
                          color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.border, width: 1.2),
                        ),
                        child: Center(
                          child: Icon(Icons.shopping_bag_outlined, color: context.textPrimary, size: 20),
                        ),
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
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
          // Ambient Glow
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(context.isDark ? 0.08 : 0.12),
                    const Color(0xFFF59E0B).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Search Bar Glass
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // Grid Limbah
                  Expanded(
                    child: _isLoading
                        ? const ProductGridShimmerSkeleton(includeSearchHeader: false)
                        : _errorMessage != null
                            ? _buildErrorState()
                            : _filteredLimbah.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _fetchLimbah,
                                    color: const Color(0xFFD97706),
                                    child: GridView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                      itemCount: _filteredLimbah.length,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 322,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemBuilder: (context, index) {
                                        final limbah = _filteredLimbah[index];
                                        final bool isPopuler = index == 0 && limbah.reviewsCount > 0;

                                        return _buildLimbahCard(
                                          context: context,
                                          limbah: limbah,
                                          isPopuler: isPopuler,
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 13.5, color: context.textPrimary),
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hintText: 'Cari produk limbah & pakan ampas...',
          hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: context.brandAmber, size: 21),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 18),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildLimbahCard({
    required BuildContext context,
    required Limbah limbah,
    required bool isPopuler,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LimbahDetailScreen(limbah: limbah)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 126,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          EcoCachedImage(
                            imageUrl: limbah.imageUrl,
                            width: double.infinity,
                            height: 126,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.recycling_rounded,
                            fallbackColor: context.brandAmber,
                            fallbackBgColor: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                          ),
                          if (isPopuler)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.eco_rounded, size: 11, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'POPULER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? const Color(0xFFD97706).withValues(alpha: 0.15) : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Limbah',
                                    style: TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: limbah.stok <= 0
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                                          : (context.isDark ? const Color(0xFFD97706).withValues(alpha: 0.15) : const Color(0xFFFFFBEB)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      limbah.stok <= 0 ? 'Habis' : 'Stok ${limbah.stok}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: limbah.stok <= 0 ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              limbah.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                height: 1.22,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final int starNo = index + 1;
                                  final bool isFilled = limbah.reviewsCount > 0 && starNo <= limbah.rating.round();
                                  return Icon(
                                    Icons.star_rounded,
                                    size: 12.5,
                                    color: isFilled ? const Color(0xFFFBBF24) : (context.isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  limbah.reviewsCount > 0 ? limbah.rating.toStringAsFixed(1) : 'Baru',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Rp ${_currencyFormat.format(limbah.priceValue)} / ${limbah.satuan}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: limbah.stok <= 0
                        ? LinearGradient(colors: [Colors.grey.shade500, Colors.grey.shade600])
                        : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: limbah.stok <= 0
                        ? null
                        : () async {
                            final canProceed = await AuthGuard.requireAuth(
                              context,
                              actionMessage: 'menambahkan limbah ke keranjang belanja',
                            );
                            if (!canProceed || !context.mounted) return;
                            Provider.of<CartProvider>(context, listen: false).addToCart(limbah.toProduct());
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${limbah.name} berhasil ditambahkan!'),
                                backgroundColor: const Color(0xFFD97706),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          limbah.stok <= 0 ? Icons.block_rounded : Icons.add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          limbah.stok <= 0 ? 'Stok Habis' : 'Tambah',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 36, color: context.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            'Produk limbah "$_searchQuery" tidak ditemukan',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan coba kata kunci lain.',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 54, color: Color(0xFFEF4444)),
              const SizedBox(height: 14),
              Text(
                'Gagal Memuat Produk Limbah',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '$_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchLimbah();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
