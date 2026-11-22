import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/limbah.dart'; 
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import 'product_detail_screen.dart';
import 'limbah_detail_screen.dart';
import 'cart_screen.dart';
import '../services/api_service.dart';
import '../widgets/auth_guard.dart';
import '../widgets/ecotahu_loader.dart';
import '../theme/app_theme.dart';

class ProductListingScreen extends StatefulWidget {
  final String initialTab;
  const ProductListingScreen({super.key, this.initialTab = 'Semua'});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late String _selectedTab;
  String? _lastSyncedNavFilter;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  final List<String> _categories = ['Semua', 'Produk Tahu', 'Produk Limbah'];

  final ApiService _apiService = ApiService();
  List<Product> _productsList = [];
  List<Limbah> _limbahList = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navFilter = context.watch<NavigationProvider>().productCategoryFilter;
    if (_lastSyncedNavFilter == null) {
      _lastSyncedNavFilter = navFilter;
      if (widget.initialTab == 'Semua') {
        _selectedTab = navFilter;
      }
    } else if (navFilter != _lastSyncedNavFilter) {
      _lastSyncedNavFilter = navFilter;
      _selectedTab = navFilter;
      _searchQuery = '';
      _searchController.clear();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final products = await _apiService.getProducts(token);
      final limbah = await _apiService.getLimbah();
      
      if (mounted) {
        setState(() {
          _productsList = products;
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

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _productsList;
    return _productsList
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
        backgroundColor: context.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Katalog Produk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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
                          color: context.isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
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
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.12),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
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
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. GLASS SEARCH BAR
                            _buildSearchBar(),
                            const SizedBox(height: 14),

                            // 2. KATEGORI TABS CAPSULES
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: _categories.map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildCategoryTab(category),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 3. PRODUCT GRID / LIST
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadData,
                                color: context.brandGreen,
                                child: _selectedTab == 'Semua'
                                    ? _buildAllList()
                                    : _selectedTab == 'Produk Tahu'
                                        ? _buildTahuList()
                                        : _buildLimbahList(),
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

  // ================= SEARCH BAR =================
  Widget _buildSearchBar() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
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
          hintText: 'Cari tahu organik & ampas...',
          hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: context.brandGreen, size: 21),
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

  // ================= CATEGORY TAB BUTTON =================
  Widget _buildCategoryTab(String title) {
    final bool isSelected = _selectedTab == title;
    final Color activeBg = title == 'Produk Limbah'
        ? (context.isDark ? const Color(0xFFD97706) : const Color(0xFFD97706))
        : context.brandGreenSolid;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
          _searchQuery = '';
          _searchController.clear();
        });
        _lastSyncedNavFilter = title;
        context.read<NavigationProvider>().setProductFilter(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBg : context.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.32),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  // ================= LIST VIEWS =================
  Widget _buildAllList() {
    if (_filteredProducts.isEmpty && _filteredLimbah.isEmpty) return _buildEmptyState();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        if (_filteredProducts.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 18, color: context.brandGreen),
              const SizedBox(width: 6),
              Text(
                'Produk Tahu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTahuGrid(_filteredProducts),
          const SizedBox(height: 25),
        ],

        if (_filteredLimbah.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.recycling_rounded, size: 18, color: context.brandAmber),
              const SizedBox(width: 6),
              Text(
                'Produk Limbah (Ampas Tahu)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLimbahGrid(_filteredLimbah),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 90), // Bottom margin for floating nav bar
      ],
    );
  }

  Widget _buildTahuList() {
    if (_filteredProducts.isEmpty) return _buildEmptyState();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        _buildTahuGrid(_filteredProducts),
        const SizedBox(height: 95),
      ],
    );
  }

  Widget _buildLimbahList() {
    if (_filteredLimbah.isEmpty) return _buildEmptyState();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        _buildLimbahGrid(_filteredLimbah),
        const SizedBox(height: 95),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 36, color: context.textMuted),
            ),
            const SizedBox(height: 14),
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
              'Coba cari dengan kata kunci lain.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================= GRIDS =================
  Widget _buildTahuGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
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

  Widget _buildLimbahGrid(List<Limbah> limbahList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: limbahList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final limbah = limbahList[index];
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

  // ================= KARTU PRODUK GLASSMORPHIC =================
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
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
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
              // Gambar Produk & Badge
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 600,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(fallbackIcon, size: 40, color: tagTextColor),
                                ),
                              )
                            : Center(
                                child: Icon(fallbackIcon, size: 40, color: tagTextColor),
                              ),
                      ),
                    ),

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

                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final int starNo = index + 1;
                            final bool isFilled = reviewsCount > 0 && starNo <= rating.round();
                            return Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: isFilled ? const Color(0xFFFBBF24) : (context.isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            reviewsCount > 0 ? rating.toStringAsFixed(1) : 'Baru',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Harga
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

                      // Tombol Tambah
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

  // ================= ERROR STATE =================
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
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.06),
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
                'Gagal Memuat Katalog',
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
                  backgroundColor: const Color(0xFF059669),
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
