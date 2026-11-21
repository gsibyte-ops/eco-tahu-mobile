import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/limbah.dart';
import '../models/article.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'product_detail_screen.dart';
import 'limbah_detail_screen.dart';
import 'article_detail_screen.dart';
import 'cart_screen.dart';
import '../services/api_service.dart';
import 'notification_screen.dart';
import '../widgets/auth_guard.dart';
import '../widgets/ecotahu_loader.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  
  List<Product> _productsList = [];
  List<Limbah> _limbahList = [];
  List<Article> _articlesList = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); 

    try {
      final products = await _apiService.getProducts(token);
      final limbah = await _apiService.getLimbah();
      int unreadNotif = 0;
      if (token != null && token.isNotEmpty) {
        final notifRes = await _apiService.getNotifications(token);
        unreadNotif = notifRes['unread_count'] ?? 0;
      }
      List<Article> articles = [];
      try {
        articles = await _apiService.getArticles(token);
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _productsList = products;
          _limbahList = limbah;
          _articlesList = articles;
          _unreadNotificationCount = unreadNotif;
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

  List<Product> get _filteredProducts {
    if (_searchQuery.isNotEmpty) {
      return _productsList
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    final ranked = List<Product>.from(_productsList)
      ..sort((a, b) {
        final revCmp = b.reviewsCount.compareTo(a.reviewsCount);
        if (revCmp != 0) return revCmp;
        final ratCmp = b.rating.compareTo(a.rating);
        if (ratCmp != 0) return ratCmp;
        return b.id.compareTo(a.id);
      });
    return ranked.take(4).toList();
  }

  List<Limbah> get _filteredLimbah {
    if (_searchQuery.isNotEmpty) {
      return _limbahList
          .where((l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    final ranked = List<Limbah>.from(_limbahList)
      ..sort((a, b) {
        final revCmp = b.reviewsCount.compareTo(a.reviewsCount);
        if (revCmp != 0) return revCmp;
        final ratCmp = b.rating.compareTo(a.rating);
        if (ratCmp != 0) return ratCmp;
        return b.id.compareTo(a.id);
      });
    return ranked.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Ambient Glow Blobs di Latar Belakang
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (context.isDark ? const Color(0xFF10B981) : const Color(0xFF10B981))
                        .withValues(alpha: context.isDark ? 0.14 : 0.18),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (context.isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                        .withValues(alpha: context.isDark ? 0.10 : 0.12),
                    const Color(0xFF059669).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const EcoTahuLoadingIndicator()
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: context.brandGreen,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. HEADER DENGAN AVATAR & GLASSED ACTION BUTTONS
                              _buildHeader(context),
                              const SizedBox(height: 18),

                              // 2. GLASS SEARCH BAR
                              _buildSearchBar(),
                              const SizedBox(height: 22),

                              // 3. HERO BANNER & KATEGORI (Hanya saat tidak search)
                              if (_searchQuery.isEmpty) ...[
                                _buildHeroBanner(),
                                const SizedBox(height: 26),

                                _buildKategoriSection(context),
                                const SizedBox(height: 18),

                                _buildResepQuickBanner(context),
                                const SizedBox(height: 28),
                              ],

                              // 4. LIST PRODUK TAHU (GRID 2 KOLOM GLASS CARDS)
                              if (_filteredProducts.isNotEmpty) ...[
                                _buildSectionHeader(
                                  title: _searchQuery.isEmpty ? 'Produk Pilihan' : 'Hasil Pencarian Tahu',
                                  subtitle: _searchQuery.isEmpty ? 'Tahu organik premium fresh dari pabrik kami.' : null,
                                  onViewAll: _searchQuery.isEmpty
                                      ? () => context
                                          .read<NavigationProvider>()
                                          .openProductsTab(filter: 'Produk Tahu')
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                _buildProductGrid(context, _filteredProducts),
                                const SizedBox(height: 30),
                              ],

                              // 5. LIST PRODUK LIMBAH (GRID 2 KOLOM GLASS CARDS)
                              if (_filteredLimbah.isNotEmpty) ...[
                                _buildSectionHeader(
                                  title: _searchQuery.isEmpty ? 'Ampas Tahu Bernilai' : 'Hasil Pencarian Limbah',
                                  subtitle: _searchQuery.isEmpty ? 'Inovasi olahan limbah zero-waste berkualitas tinggi.' : null,
                                  onViewAll: _searchQuery.isEmpty
                                      ? () => context
                                          .read<NavigationProvider>()
                                          .openProductsTab(filter: 'Produk Limbah')
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                _buildLimbahGrid(context, _filteredLimbah),
                                const SizedBox(height: 30),
                              ],

                              // 6. TAMPILAN KOSONG
                              if (_filteredProducts.isEmpty && _filteredLimbah.isEmpty)
                                _buildEmptySearchState(),

                              // 7. EDUKASI LINGKUNGAN (Hanya saat tidak search)
                              if (_searchQuery.isEmpty) ...[
                                _buildSectionHeader(
                                  title: 'Edukasi Lingkungan',
                                  subtitle: 'Artikel & tips gaya hidup berkelanjutan EcoTahu.',
                                  onViewAll: () => context.read<NavigationProvider>().setTab(3),
                                ),
                                const SizedBox(height: 14),
                                _buildEdukasiHomeSection(context),
                                const SizedBox(height: 20),
                              ],

                              // Bottom Padding agar tidak tertutup floating bottom nav bar
                              const SizedBox(height: 95),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ================= WIDGET: HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final String displayName = auth.isLoggedIn && auth.userName.isNotEmpty
            ? auth.userName.split(' ').first
            : 'Sobat Tahu';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Logo Icon Capsule
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $displayName!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sehat untukmu, ramah untuk bumi',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Action Buttons (Tema + Notifikasi + Keranjang)
            Row(
              children: [
                // Theme Toggle Button
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    final isDark = themeProvider.isDark(context);
                    return _buildGlassIconButton(
                      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                      iconColor: isDark ? const Color(0xFFFBBF24) : context.textPrimary,
                      badgeCount: 0,
                      onTap: () => themeProvider.toggleTheme(context),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Notifikasi Button
                _buildGlassIconButton(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: _unreadNotificationCount,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),

                // Keranjang Button
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final totalItems = cart.items.fold(0, (sum, item) => sum + item.quantity);
                    return _buildGlassIconButton(
                      icon: Icons.shopping_bag_outlined,
                      badgeCount: totalItems,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartScreen()),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required int badgeCount,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.glassBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.glassBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: context.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor ?? context.textPrimary, size: 20),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
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
    );
  }

  // ================= WIDGET: SEARCH BAR =================
  Widget _buildSearchBar() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
          hintText: 'Cari tahu organik, ampas kedelai...',
          hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: context.brandGreen, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: context.textMuted, size: 18),
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

  // ================= WIDGET: HERO BANNER (GLASS ORGANIC) =================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle circular background glow inside banner
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eco Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF6EE7B7), size: 14),
                    SizedBox(width: 6),
                    Text(
                      '100% Organik & Zero-Waste',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Tahu Segar,\nBumi Lestari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Olahan kedelai pilihan dengan standar higienis tinggi dan pemanfaatan ampas tahu bernilai guna.',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Glass Stats Strip
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroStat('21+', 'Pesanan'),
                        Container(height: 22, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _buildHeroStat('5.0', 'Ulasan Puas', prefixIcon: Icons.star_rounded, prefixIconColor: const Color(0xFFFBBF24)),
                        Container(height: 22, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _buildHeroStat('${_productsList.length + _limbahList.length}', 'Varian Produk'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(
    String value,
    String label, {
    IconData? prefixIcon,
    Color? prefixIconColor,
  }) {
    return Column(
      children: [
        if (prefixIcon != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(prefixIcon, size: 15, color: prefixIconColor ?? const Color(0xFF6EE7B7)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================= WIDGET: KATEGORI PRODUK =================
  Widget _buildKategoriSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Pilihan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jelajahi varian tahu segar atau olahan ampas bernutrisi.',
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            // Kategori Tahu
            Expanded(
              child: _buildCategoryGlassCard(
                title: 'Produk Tahu',
                subtitle: 'Segar & Gurih',
                count: '${_productsList.length} Pilihan',
                icon: Icons.eco_rounded,
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                glowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                pillBgColor: context.tahuTagBg,
                pillBorderColor: context.tahuTagBorder,
                pillTextColor: context.tahuTagText,
                onTap: () => context
                    .read<NavigationProvider>()
                    .openProductsTab(filter: 'Produk Tahu'),
              ),
            ),
            const SizedBox(width: 14),

            // Kategori Limbah
            Expanded(
              child: _buildCategoryGlassCard(
                title: 'Ampas Tahu',
                subtitle: 'Pakan & Pupuk',
                count: '${_limbahList.length} Pilihan',
                icon: Icons.recycling_rounded,
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                glowColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                pillBgColor: context.limbahTagBg,
                pillBorderColor: context.limbahTagBorder,
                pillTextColor: context.limbahTagText,
                onTap: () => context
                    .read<NavigationProvider>()
                    .openProductsTab(filter: 'Produk Limbah'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryGlassCard({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required List<Color> gradientColors,
    required Color glowColor,
    required Color pillBgColor,
    required Color pillBorderColor,
    required Color pillTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 16, color: context.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pillBorderColor, width: 1),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: pillTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResepQuickBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setTab(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resep Olahan Tahu',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inspirasi masakan tahu lezat & sehat',
                    style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 15, color: context.brandGreen),
          ],
        ),
      ),
    );
  }

  String _formatArticleDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEdukasiHomeSection(BuildContext context) {
    final items = _articlesList.take(4).toList();
    if (items.isEmpty) {
      return GestureDetector(
        onTap: () => context.read<NavigationProvider>().setTab(3),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Artikel Edukasi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pelajari olahan limbah ramah lingkungan bersama EcoTahu',
                      style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: context.brandGreen),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _buildEdukasiHomeCard(context, items[index]),
      ),
    );
  }

  Widget _buildEdukasiHomeCard(BuildContext context, Article article) {
    final bool isYoutube = article.mediaType == 'youtube';
    final bool isVideo = article.mediaType == 'video';
    final String imgUrl = article.displayImageUrl;

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
            );
            if (result is Map && result['id'] == article.id && mounted) {
              setState(() {
                final idx = _articlesList.indexWhere((a) => a.id == article.id);
                if (idx != -1) {
                  _articlesList[idx] = _articlesList[idx].copyWith(
                    isLiked: result['is_liked'] == true,
                    likesCount: result['likes_count'] ?? _articlesList[idx].likesCount,
                  );
                }
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Media
              SizedBox(
                height: 118,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imgUrl.isNotEmpty)
                        Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildEdukasiCoverFallback(
                            context,
                            isVideo || isYoutube,
                          ),
                        )
                      else
                        _buildEdukasiCoverFallback(context, isVideo || isYoutube),
                      // Subtle bottom scrim
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                      // Category Pill top-left
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            article.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      // Media badge top-right
                      if (isYoutube || isVideo)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: (isYoutube ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isYoutube ? Icons.play_arrow_rounded : Icons.videocam_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isYoutube ? 'YouTube' : 'Video',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
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

              // Editorial Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: context.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11.5, color: context.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _formatArticleDate(article.date),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            article.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 12.5,
                            color: article.isLiked ? const Color(0xFFF43F5E) : context.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${article.likesCount}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Baca',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.brandGreenBright,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_forward_rounded, size: 13, color: context.brandGreenBright),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdukasiCoverFallback(BuildContext context, bool isVideoMedia) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark
              ? const [Color(0xFF064E3B), Color(0xFF0F172A)]
              : const [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isVideoMedia ? Icons.play_circle_outline_rounded : Icons.menu_book_rounded,
          size: 38,
          color: context.brandGreen,
        ),
      ),
    );
  }

  // ================= WIDGET: SECTION HEADER =================
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                ),
              ]
            ],
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.tahuTagBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.tahuTagBorder, width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: context.brandGreenBright,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, color: context.brandGreenBright, size: 13),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ================= WIDGET: PRODUK GRID (2 KOLOM GLASS CARDS) =================
  Widget _buildProductGrid(BuildContext context, List<Product> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final product = list[index];
        final bool isTerlaris = index == 0 && product.reviewsCount > 0;

        return _buildProductCard(
          context: context,
          id: product.id,
          name: product.name,
          categoryName: 'Tahu',
          imageUrl: product.imageUrl,
          priceValue: product.priceValue,
          unit: product.satuan,
          rating: product.rating,
          reviewsCount: product.reviewsCount,
          badgeText: isTerlaris ? 'TERLARIS' : null,
          badgeIcon: Icons.local_fire_department_rounded,
          badgeColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
          tagBgColor: context.tahuTagBg,
          tagBorderColor: context.tahuTagBorder,
          tagTextColor: context.tahuTagText,
          priceColor: context.brandGreen,
          btnGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          fallbackIcon: Icons.eco_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
            );
          },
          onAddToCart: () async {
            final canProceed = await AuthGuard.requireAuth(
              context,
              actionMessage: 'menambahkan produk ke keranjang belanja',
            );
            if (!canProceed || !context.mounted) return;
            Provider.of<CartProvider>(context, listen: false).addToCart(product);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} berhasil ditambahkan!'),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        );
      },
    );
  }

  // ================= WIDGET: LIMBAH GRID (2 KOLOM GLASS CARDS) =================
  Widget _buildLimbahGrid(BuildContext context, List<Limbah> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final limbah = list[index];
        final bool isPopuler = index == 0 && limbah.reviewsCount > 0;

        return _buildProductCard(
          context: context,
          id: limbah.id,
          name: limbah.name,
          categoryName: 'Limbah',
          imageUrl: limbah.imageUrl,
          priceValue: limbah.priceValue,
          unit: limbah.satuan,
          rating: limbah.rating,
          reviewsCount: limbah.reviewsCount,
          badgeText: isPopuler ? 'POPULER' : null,
          badgeIcon: Icons.eco_rounded,
          badgeColors: const [Color(0xFF10B981), Color(0xFF059669)],
          tagBgColor: context.limbahTagBg,
          tagBorderColor: context.limbahTagBorder,
          tagTextColor: context.limbahTagText,
          priceColor: context.brandAmber,
          btnGradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          fallbackIcon: Icons.recycling_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LimbahDetailScreen(limbah: limbah)),
            );
          },
          onAddToCart: () async {
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
        );
      },
    );
  }

  // ================= WIDGET: KARTU PRODUK GLASSMORPHIC =================
  Widget _buildProductCard({
    required BuildContext context,
    required int id,
    required String name,
    required String categoryName,
    required String imageUrl,
    required int priceValue,
    required double rating,
    required int reviewsCount,
    String? unit,
    String? badgeText,
    IconData? badgeIcon,
    required List<Color> badgeColors,
    required Color tagBgColor,
    required Color tagBorderColor,
    required Color tagTextColor,
    required Color priceColor,
    required List<Color> btnGradient,
    required IconData fallbackIcon,
    required VoidCallback onTap,
    required VoidCallback onAddToCart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Produk & Badge Floating
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: context.surfaceElevated,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(fallbackIcon, size: 42, color: tagTextColor),
                                ),
                              )
                            : Center(
                                child: Icon(fallbackIcon, size: 42, color: tagTextColor),
                              ),
                      ),
                    ),

                    // Badge Terlaris / Populer
                    if (badgeText != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: badgeColors),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColors.first.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeIcon != null) ...[
                                Icon(badgeIcon, size: 11, color: Colors.white),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                badgeText,
                                style: const TextStyle(
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

              // Detail Produk
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: tagBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tagBorderColor, width: 1),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: tagTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Nama Produk
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.25,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating & Ulasan
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final int starNo = index + 1;
                            final bool isFilled = reviewsCount > 0 && starNo <= rating.round();
                            return Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: isFilled
                                  ? const Color(0xFFFBBF24)
                                  : (context.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            reviewsCount > 0
                                ? '${rating.toStringAsFixed(1)}'
                                : 'Baru',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Harga Produk
                      Text(
                        'Rp ${_currencyFormat.format(priceValue)}${unit != null ? ' / $unit' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: priceColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tombol Tambah ke Keranjang
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: btnGradient),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: btnGradient.last.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: onAddToCart,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGET: ERROR STATE =================
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
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF0F172A).withValues(alpha: 0.06),
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
                'Gagal Memuat Data',
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
                  _loadData();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brandGreen,
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

  // ================= WIDGET: EMPTY SEARCH STATE =================
  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 40, color: context.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'Produk "$_searchQuery" tidak ditemukan',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Coba gunakan kata kunci lain seperti "tahu" atau "ampas".',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
