import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart'; // Biarkan jika masih dipakai
import '../services/api_service.dart'; // Import API Service
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'admin_overview_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'edit_profile_screen.dart';
import 'my_orders_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'help_screen.dart';
import 'how_to_order_screen.dart';
import 'shipping_info_screen.dart';
import 'refund_policy_screen.dart';
import 'faq_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  String? _token;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fungsi untuk mengambil data profil dari API
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).setAdminStatus(false);
        if (!mounted) return;
        Provider.of<CartProvider>(context, listen: false).setAdminMode(false);
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _token = null;
      });
      return;
    }

    final user = await _apiService.getUserProfile(token);
    if (!mounted) return;

    final isAdmin = AuthProvider.isAdminFromUserMap(user);
    await Provider.of<AuthProvider>(context, listen: false).setAdminStatus(isAdmin);
    if (!mounted) return;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.setAdminMode(isAdmin);
    if (!isAdmin) {
      cartProvider.syncWithServer();
    }

    setState(() {
      _token = token;
      _userData = user;
      _isLoading = false;
    });
  }

  // Fungsi untuk Logout
  Future<void> _handleLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: AppTheme.textGrey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true && _token != null) {
      // 1. Tembak API Logout Laravel
      await _apiService.logout(_token!);
      
      // 2. Hapus token & status role dari HP (keranjang tetap tersimpan)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('is_admin');
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).setAdminStatus(false);
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).setAdminMode(false);
        }
      }

      // 3. Pindah ke halaman Login & hapus history navigasi
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil keluar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: context.brandGreen))
            : _token == null || _userData == null
                ? _buildNotLoggedIn(context) // Tampilan belum login
                : _buildLoggedIn(context), // Tampilan sudah login
      ),
    );
  }

  // ============ JIKA BELUM LOGIN (MODE PENGUNJUNG / GUEST) ============
  Widget _buildNotLoggedIn(BuildContext context) {
    return Stack(
      children: [
        // Ambient background circles (menjaga estetika visual tetap segar)
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 350,
          left: -50,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Konten Scrollable
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO CARD: Mode Tamu & Ajakan Masuk
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar Tamu dengan Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4),
                            border: Border.all(color: context.isDark ? AppTheme.emeraldLight : Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E8E5A).withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 46,
                            color: Color(0xFF1E8E5A),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E8E5A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.eco, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badge Mode Tamu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.tahuTagBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.tahuTagBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, size: 13, color: context.brandGreen),
                          const SizedBox(width: 5),
                          Text(
                            'Mode Pengunjung',
                            style: TextStyle(
                              color: context.brandGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Silakan Masuk ke Akunmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk atau daftar untuk melihat pesanan, simpan alamat, dan nikmati fitur lengkap EcoTahu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Aksi: Masuk & Daftar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                              _loadUserProfile();
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text(
                              'Masuk',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E8E5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 3,
                              shadowColor: const Color(0xFF1E8E5A).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                              _loadUserProfile();
                            },
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            label: const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E8E5A),
                              side: const BorderSide(color: Color(0xFF1E8E5A), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 2. SECTION: PUSAT BANTUAN & LAYANAN (GRID 2x2)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Bantuan & Panduan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Informasi dan layanan pelanggan dapat diakses kapan saja',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),

              // GRID 2x2
              Row(
                children: [
                  Expanded(
                    child: _buildQuickGridItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Pusat Bantuan',
                      subtitle: 'CS & WhatsApp',
                      iconColor: context.brandGreen,
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickGridItem(
                      icon: Icons.quiz_outlined,
                      title: 'Tanya Jawab',
                      subtitle: 'FAQ & Solusi',
                      iconColor: context.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickGridItem(
                      icon: Icons.menu_book_rounded,
                      title: 'Cara Pesan',
                      subtitle: 'Panduan belanja',
                      iconColor: context.brandAmber,
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HowToOrderScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickGridItem(
                      icon: Icons.local_shipping_rounded,
                      title: 'Pengiriman',
                      subtitle: 'Radius & ongkir',
                      iconColor: context.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                      bgColor: const Color(0xFFF0FDFA),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShippingInfoScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 3. SECTION: TAMPILAN & PENGATURAN
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Pengaturan Aplikasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          secondary: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.isDark ? AppTheme.emeraldDarkSoft : AppTheme.lightGreen.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              context.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: context.brandGreen,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            'Mode Gelap',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary),
                          ),
                          subtitle: Text(
                            context.isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                            style: TextStyle(color: context.textSecondary, fontSize: 12),
                          ),
                          activeColor: context.brandGreen,
                          value: context.isDark,
                          onChanged: (val) {
                            themeProvider.toggleTheme(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 4. SECTION: KEBIJAKAN & TRANSPARANSI
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Kebijakan & Transparansi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.assignment_return_outlined,
                      title: 'Kebijakan Refund',
                      subtitle: 'Ketentuan garansi & pengembalian dana',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RefundPolicyScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuTile(
                      icon: Icons.description_outlined,
                      title: 'Syarat & Ketentuan',
                      subtitle: 'Ketentuan penggunaan layanan EcoTahu',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Kebijakan Privasi',
                      subtitle: 'Perlindungan & privasi data pengguna',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 5. FOOTER INFO
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco, color: Color(0xFF1E8E5A), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'EcoTahu Mobile App · v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tahu Organik & Pengolahan Zero-Waste Jember',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }

  // Helper untuk Quick Grid Card
  Widget _buildQuickGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border),
            boxShadow: [
              BoxShadow(
                color: context.isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.isDark ? iconColor.withValues(alpha: 0.18) : bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ JIKA SUDAH LOGIN ============
  Widget _buildLoggedIn(BuildContext context) {
    // Mengambil jumlah order (jika masih pakai provider lokal)
    int orderCount = 0;
    try {
      orderCount = Provider.of<OrderProvider>(context).orders.length;
    } catch (e) {
      // Abaikan jika provider belum di-setup
    }

    // Data dari API Laravel
    String username = _userData?['username'] ?? 'Pengguna';
    String email = _userData?['email'] ?? '';
    final roleName = (_userData?['role'] is Map
            ? _userData!['role']['nama_role']?.toString().toLowerCase()
            : null) ??
        '';
    final bool isAdmin = roleName == 'admin' ||
        _userData?['role_id'] == 1 ||
        _userData?['role_id']?.toString() == '1';

    String resolvedAvatar = AppConfig.fileUrl(
      (_userData?['avatar_url']?.toString().trim().isNotEmpty == true)
          ? _userData!['avatar_url'].toString()
          : _userData?['avatar']?.toString(),
    );
    String? avatarUrl = resolvedAvatar.isNotEmpty ? resolvedAvatar : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // ================= 1. HEADER PROFIL =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.isDark ? AppTheme.emeraldDarkSoft : AppTheme.lightGreen,
                    border: Border.all(color: context.isDark ? AppTheme.emeraldLight : Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            cacheWidth: 400,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: Color(0xFF1E8E5A)),
                          )
                        : const Icon(Icons.person, size: 60, color: Color(0xFF1E8E5A)),
                  ),
                ),
                const SizedBox(height: 15),
                Text(username, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary)),
                const SizedBox(height: 5),
                Text(email, style: TextStyle(color: context.textSecondary, fontSize: 14)),
                if (isAdmin) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'Admin EcoTahu · Read-Only',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    _loadUserProfile();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E8E5A), 
                    side: const BorderSide(color: Color(0xFF1E8E5A)), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (isAdmin) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminOverviewScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Admin (Overview)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pantau statistik bisnis, refund & konten secara Read-Only',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ================= 2. MENU (GROUPED LIST) =================
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMenuTile(
                  icon: Icons.receipt_long_outlined, 
                  title: 'Pesanan Saya', 
                  subtitle: orderCount > 0 ? '$orderCount pesanan' : 'Riwayat belanja', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.location_on_outlined, 
                  title: 'Alamat Pengiriman', 
                  subtitle: 'Kelola alamat & profil',
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    _loadUserProfile();
                  },
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.lock_reset_outlined, 
                  title: 'Ganti Password', 
                  subtitle: 'Perbarui kata sandi akun', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()))
                ),
                _buildDivider(),
                // Mode Gelap Toggle di Profile
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDark ? AppTheme.emeraldDarkSoft : AppTheme.lightGreen.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          context.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: const Color(0xFF1E8E5A),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Mode Gelap',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary),
                      ),
                      subtitle: Text(
                        context.isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                      ),
                      activeColor: const Color(0xFF1E8E5A),
                      value: context.isDark,
                      onChanged: (val) {
                        themeProvider.toggleTheme(context);
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.support_agent_outlined, 
                  title: 'Pusat Bantuan', 
                  subtitle: 'Kontak CS & jam operasional',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.menu_book_outlined, 
                  title: 'Cara Pesan', 
                  subtitle: 'Panduan belanja langkah demi langkah',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HowToOrderScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.local_shipping_outlined, 
                  title: 'Informasi Pengiriman', 
                  subtitle: 'Jangkauan radius 10 km & ongkir',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShippingInfoScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.assignment_return_outlined, 
                  title: 'Kebijakan Refund', 
                  subtitle: 'Ketentuan pengembalian dana',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RefundPolicyScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.help_outline, 
                  title: 'Tanya Jawab (FAQ)', 
                  subtitle: 'Jawaban seputar tahu & ampas',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.description_outlined, 
                  title: 'Syarat & Ketentuan', 
                  subtitle: 'Ketentuan penggunaan EcoTahu',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen())),
                ),
                _buildDivider(),
                _buildMenuTile(
                  icon: Icons.privacy_tip_outlined, 
                  title: 'Kebijakan Privasi', 
                  subtitle: 'Perlindungan data pengguna',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen())),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          // ================= 3. TOMBOL KELUAR =================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout, // Panggil fungsi logout baru
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16), 
                side: BorderSide(
                  color: context.isDark ? const Color(0xFFDC2626).withOpacity(0.4) : Colors.red.shade200, 
                  width: 1.5,
                ), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: context.isDark ? const Color(0xFF7F1D1D).withOpacity(0.2) : Colors.red.shade50,
              ),
            ),
          ),

          if (!isAdmin) ...[
            const SizedBox(height: 20),

            // ================= 4. HAPUS AKUN =================
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteAccountScreen())),
              child: Text(
                'Hapus Akun Saya',
                style: TextStyle(color: context.textMuted, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
          ],
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  // ================= WIDGET HELPER =================
  
  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.tahuTagBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.brandGreen, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(color: context.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1, 
      thickness: 1, 
      color: context.border, 
      indent: 70,
      endIndent: 20,
    );
  }
}