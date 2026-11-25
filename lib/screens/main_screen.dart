import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/store_provider.dart';
import '../services/local_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_banner.dart';
import 'home_screen.dart';
import 'product_listing_screen.dart';
import 'recipe_screen.dart';
import 'education_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final List<Widget> _pages = const [
    HomeScreen(),
    ProductListingScreen(),
    RecipeScreen(),
    EducationScreen(),
    ProfileScreen(),
  ];

  ConnectivityProvider? _connectivityProvider;
  Future<void> Function()? _reconnectCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      if (widget.initialIndex != 0) {
        navProvider.setTab(widget.initialIndex);
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      _connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);

      // Daftarkan auto-sync ketika koneksi kembali online
      _reconnectCallback = () async {
        await authProvider.syncRoleFromServer();
        cartProvider.setAdminMode(authProvider.isAdmin);
        if (!authProvider.isAdmin) {
          await cartProvider.syncWithServer();
        }
        await storeProvider.loadStoreInfo(force: true);
        await LocalNotificationService.instance.pollNow();
      };
      _connectivityProvider?.addReconnectListener(_reconnectCallback!);

      // Minta izin push notification Android 13+ dan mulai polling notifikasi server
      await LocalNotificationService.instance.requestPermission();
      LocalNotificationService.instance.startPolling();

      await authProvider.syncRoleFromServer();
      if (!mounted) return;

      cartProvider.setAdminMode(authProvider.isAdmin);
      if (!authProvider.isAdmin) {
        await cartProvider.syncWithServer();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectivityProvider?.checkNow();
      LocalNotificationService.instance.pollNow();
      if (mounted) {
        final cart = Provider.of<CartProvider>(context, listen: false);
        if (cart.hasPendingSync) {
          cart.syncWithServer();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_reconnectCallback != null) {
      _connectivityProvider?.removeReconnectListener(_reconnectCallback!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBody: true, // Biarkan konten scroll sedikit di balik nav bar kaca
      body: Column(
        children: [
          // Banner status offline/online global — muncul untuk Guest, Pelanggan, maupun Admin
          const SafeArea(
            bottom: false,
            child: OfflineStatusBanner(),
          ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassmorphicNavBar(context, currentIndex),
    );
  }

  Widget _buildGlassmorphicNavBar(BuildContext context, int currentIndex) {
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? AppTheme.emeraldLight : AppTheme.primaryGreen)
                .withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.glassBg,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: context.glassBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, currentIndex, 0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
                _buildNavItem(context, currentIndex, 1, Icons.storefront_rounded, Icons.storefront_outlined, 'Produk'),
                _buildNavItem(context, currentIndex, 2, Icons.restaurant_menu_rounded, Icons.restaurant_menu_outlined, 'Resep'),
                _buildNavItem(context, currentIndex, 3, Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Edukasi'),
                _buildNavItem(context, currentIndex, 4, Icons.person_rounded, Icons.person_outline_rounded, 'Akun'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int currentIndex,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool isSelected = currentIndex == index;
    final Color activeGreen = context.brandGreen;

    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeGreen.withValues(alpha: context.isDark ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 22,
              color: isSelected ? activeGreen : context.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: activeGreen,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
