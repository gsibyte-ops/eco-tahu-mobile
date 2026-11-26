import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/local_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_preview_widgets.dart';
import '../widgets/offline_banner.dart';
import '../widgets/shimmer_skeletons.dart';
import '../services/secure_storage_service.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      if (_data.isEmpty) _isLoading = true;
      _errorMessage = null;
    });

    final token = (await SecureStorageService.readToken()) ?? '';
    if (token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sesi admin tidak ditemukan. Silakan login ulang.';
        });
      }
      return;
    }

    // 1. Tampilkan cache lokal secara instan agar langsung terbaca saat offline
    final cached = await LocalCacheService.readJson(LocalCacheService.keyAdminOverview);
    if (cached is Map && mounted) {
      setState(() {
        _data = Map<String, dynamic>.from(cached);
        _errorMessage = null;
        _isLoading = false;
      });
    }

    // 2. Refresh live dari server
    final res = await _apiService.getAdminOverview(token);
    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      setState(() {
        _data = Map<String, dynamic>.from(res['data']);
        _errorMessage = null;
        _isLoading = false;
      });
    } else if (_data.isEmpty) {
      setState(() {
        _errorMessage = res['message']?.toString() ?? 'Gagal memuat overview admin.';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  int _asInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  double _asDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _compactRupiah(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}Jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return '$amount';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'diproses':
      case 'dikirim':
        return const Color(0xFF2563EB);
      case 'selesai':
        return const Color(0xFF059669);
      case 'dibatalkan':
      case 'ditolak':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _openVideoDialog(String rawUrl) {
    final resolved = AppConfig.fileUrl(rawUrl);
    if (resolved.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
            InlineVideoPlayer(
              videoUrl: resolved,
              height: 260,
              borderRadius: BorderRadius.circular(18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = Map<String, dynamic>.from((_data['stats'] as Map?) ?? {});
    final chart7 = (_data['chart_7_hari'] as List?) ?? [];
    final topProducts = (_data['produk_terlaris'] as List?) ?? [];
    final latestOrders = (_data['pesanan_terbaru'] as List?) ?? [];
    final latestRefunds = (_data['refund_terbaru'] as List?) ?? [];
    final latestReviews = (_data['ulasan_terbaru'] as List?) ?? [];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              'Dashboard Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
              ),
              child: Text(
                'READ-ONLY',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadOverview,
            tooltip: 'Refresh Data',
            icon: Icon(Icons.refresh_rounded, color: context.brandGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: _isLoading
                ? const AdminOverviewShimmerSkeleton()
                : _errorMessage != null
                    ? _buildErrorView()
                    : RefreshIndicator(
                  color: context.brandGreen,
                  onRefresh: _loadOverview,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_asInt(stats['refund_pending']) > 0) ...[
                          _buildPendingRefundBanner(_asInt(stats['refund_pending'])),
                          const SizedBox(height: 16),
                        ],

                        // 4 Primary KPI Cards
                        _buildSectionTitle('Ringkasan Bisnis', 'Statistik utama operasional EcoTahu'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Pendapatan',
                                value: 'Rp ${_currencyFormat.format(_asInt(stats['total_pendapatan']))}',
                                subtitle: 'Bulan ini: Rp ${_compactRupiah(_asInt(stats['pendapatan_bulan_ini']))}',
                                icon: Icons.payments_rounded,
                                accentColor: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Total Pesanan',
                                value: '${_asInt(stats['total_pesanan'])}',
                                subtitle: 'Selesai: ${_asInt(stats['pesanan_selesai'])}',
                                icon: Icons.shopping_bag_rounded,
                                accentColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Pelanggan',
                                value: '${_asInt(stats['total_pelanggan'])}',
                                subtitle: 'Akun terdaftar aktif',
                                icon: Icons.people_alt_rounded,
                                accentColor: const Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Stok Produk',
                                value: '${_asInt(stats['total_produk'])} unit',
                                subtitle: 'Tahu ${_asInt(stats['total_tahu'])} · Limbah ${_asInt(stats['total_limbah'])}',
                                icon: Icons.inventory_2_rounded,
                                accentColor: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Order Status Breakdown Strip
                        _buildStatusStrip(stats),
                        const SizedBox(height: 22),

                        // 4 Content & Engagement Mini Cards
                        _buildSectionTitle('Konten, Ulasan & Refund', 'Performa artikel, resep, dan ulasan media'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                icon: Icons.auto_stories_rounded,
                                iconColor: context.brandGreen,
                                title: 'Edukasi',
                                primary: '${_asInt(stats['edukasi_publish'])}/${_asInt(stats['total_edukasi'])}',
                                secondaryIcon: Icons.favorite_rounded,
                                secondaryIconColor: const Color(0xFFEF4444),
                                secondary: '${_asInt(stats['total_edukasi_likes'])} suka',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniStatCard(
                                icon: Icons.restaurant_menu_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                title: 'Resep Tahu',
                                primary: '${_asInt(stats['resep_publish'])}/${_asInt(stats['total_resep'])}',
                                secondaryIcon: Icons.favorite_rounded,
                                secondaryIconColor: const Color(0xFFEF4444),
                                secondary: '${_asInt(stats['total_resep_likes'])} suka',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                icon: Icons.star_rounded,
                                iconColor: context.brandAmber,
                                title: 'Ulasan',
                                primary: '${_asInt(stats['total_ulasan'])} (${_asDouble(stats['rating_rata']).toStringAsFixed(1)})',
                                secondaryIcon: Icons.perm_media_rounded,
                                secondaryIconColor: context.textSecondary,
                                secondary: '${_asInt(stats['ulasan_bermedia'])} bermedia',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniStatCard(
                                icon: Icons.account_balance_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                                title: 'Refund',
                                primary: '${_asInt(stats['refund_pending'])} pending',
                                secondary: 'Total ${_asInt(stats['total_refund'])} ajuan',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 7-Day Sales Bar Chart
                        _buildSectionTitle('Grafik Penjualan 7 Hari', 'Omzet harian dari transaksi valid'),
                        const SizedBox(height: 12),
                        _buildSalesChartCard(chart7),
                        const SizedBox(height: 24),

                        // Top 5 Products
                        _buildSectionTitle('Produk Terlaris', 'Produk & olahan limbah paling diminati'),
                        const SizedBox(height: 12),
                        _buildTopProductsCard(topProducts),
                        const SizedBox(height: 24),

                        // Latest 5 Orders
                        _buildSectionTitle('Pesanan Terbaru', '5 transaksi terakhir yang masuk'),
                        const SizedBox(height: 12),
                        _buildLatestOrdersCard(latestOrders),
                        const SizedBox(height: 24),

                        // Latest 5 Refunds + Rekening Info
                        _buildSectionTitle('Refund & Pembatalan Terbaru', 'Lengkap dengan alasan & rekening tujuan'),
                        const SizedBox(height: 12),
                        _buildLatestRefundsCard(latestRefunds),
                        const SizedBox(height: 24),

                        // Latest 5 Reviews + Media Preview
                        _buildSectionTitle('Ulasan Terbaru', 'Ulasan pelanggan beserta foto/video'),
                        const SizedBox(height: 12),
                        _buildLatestReviewsCard(latestReviews),
                        const SizedBox(height: 22),

                        // Read-Only Info Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? AppTheme.emeraldDarkSoft.withValues(alpha: 0.35)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: context.isDark
                                  ? AppTheme.emeraldLight.withValues(alpha: 0.3)
                                  : const Color(0xFF10B981).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, color: context.brandGreen, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Mode Overview (Read-Only). Pengelolaan data, verifikasi pembayaran, dan proses refund dilakukan melalui Dashboard Admin Web.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, color: Colors.redAccent, size: 54),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOverview,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRefundBanner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: context.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ada $count pengajuan refund menunggu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Proses verifikasi dan transfer balik lewat Admin Web.',
                  style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.textSecondary)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 19),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 11.5, color: context.textSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip(Map<String, dynamic> stats) {
    final items = [
      {'label': 'Pending', 'val': _asInt(stats['pesanan_pending']), 'color': const Color(0xFFD97706)},
      {'label': 'Proses', 'val': _asInt(stats['pesanan_diproses']), 'color': const Color(0xFF2563EB)},
      {'label': 'Kirim', 'val': _asInt(stats['pesanan_dikirim']), 'color': const Color(0xFF0891B2)},
      {'label': 'Selesai', 'val': _asInt(stats['pesanan_selesai']), 'color': const Color(0xFF059669)},
      {'label': 'Batal', 'val': _asInt(stats['pesanan_dibatalkan']), 'color': const Color(0xFFDC2626)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final color = item['color'] as Color;
          return Column(
            children: [
              Text(
                '${item['val']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                item['label'] as String,
                style: TextStyle(fontSize: 10.5, color: context.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String primary,
    required String secondary,
    IconData? secondaryIcon,
    Color? secondaryIconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                if (secondaryIcon != null)
                  Row(
                    children: [
                      Icon(secondaryIcon, size: 12, color: secondaryIconColor ?? context.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartCard(List chart7) {
    int maxVal = 1;
    for (final row in chart7) {
      final total = _asInt((row as Map)['total']);
      if (total > maxVal) maxVal = total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: chart7.map((raw) {
            final row = raw as Map;
            final total = _asInt(row['total']);
            final label = row['label']?.toString() ?? '';
            final ratio = maxVal > 0 ? (total / maxVal) : 0.0;
            final barHeight = total > 0 ? (ratio * 96).clamp(10.0, 96.0) : 6.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      total > 0 ? _compactRupiah(total) : '0',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: barHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: total > 0
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [context.border, context.border],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProductsCard(List topProducts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: topProducts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada data penjualan produk', style: TextStyle(color: context.textMuted, fontSize: 12.5)),
              ),
            )
          : Column(
              children: List.generate(topProducts.length, (idx) {
                final item = topProducts[idx] as Map;
                return Padding(
                  padding: EdgeInsets.only(bottom: idx == topProducts.length - 1 ? 0 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['nama_produk']?.toString() ?? '-',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_asInt(item['total_terjual'])} terjual',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.brandGreen),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildLatestOrdersCard(List latestOrders) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: latestOrders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada pesanan masuk', style: TextStyle(color: context.textMuted, fontSize: 12.5)),
              ),
            )
          : Column(
              children: List.generate(latestOrders.length, (idx) {
                final o = latestOrders[idx] as Map;
                final status = o['order_status']?.toString() ?? 'pending';
                final stColor = _statusColor(status);

                return Container(
                  margin: EdgeInsets.only(bottom: idx == latestOrders.length - 1 ? 0 : 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${o['kode_pesanan'] ?? '-'} · ${o['customer'] ?? '-'}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${o['payment_method'] ?? '-'} · ${o['tanggal'] ?? ''}',
                              style: TextStyle(fontSize: 11, color: context.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp ${_currencyFormat.format(_asInt(o['total_harga']))}',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: context.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: stColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildLatestRefundsCard(List latestRefunds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: latestRefunds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada pengajuan refund', style: TextStyle(color: context.textMuted, fontSize: 12.5)),
              ),
            )
          : Column(
              children: List.generate(latestRefunds.length, (idx) {
                final r = latestRefunds[idx] as Map;
                final status = r['status_refund']?.toString() ?? 'pending';
                final stColor = _statusColor(status);
                final bank = r['nama_bank']?.toString() ?? '';
                final norek = r['nomor_rekening']?.toString() ?? '';
                final an = r['atas_nama']?.toString() ?? '';
                final hasRekening = bank.isNotEmpty || norek.isNotEmpty || an.isNotEmpty;

                return Container(
                  margin: EdgeInsets.only(bottom: idx == latestRefunds.length - 1 ? 0 : 12),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '#${r['kode_pesanan'] ?? '-'} · ${r['customer'] ?? '-'}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: stColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nominal: Rp ${_currencyFormat.format(_asInt(r['nominal_refund']))}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.brandGreen),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Alasan: ${r['alasan_batal'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4),
                      ),
                      if (hasRekening) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_rounded, size: 14, color: context.brandGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${bank.isNotEmpty ? bank : '-'} · ${norek.isNotEmpty ? norek : '-'}${an.isNotEmpty ? ' (a.n. $an)' : ''}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildLatestReviewsCard(List latestReviews) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: latestReviews.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada ulasan pelanggan', style: TextStyle(color: context.textMuted, fontSize: 12.5)),
              ),
            )
          : Column(
              children: List.generate(latestReviews.length, (idx) {
                final rev = latestReviews[idx] as Map;
                final rating = _asInt(rev['rating']).clamp(1, 5);
                final comment = rev['komentar']?.toString() ?? '';
                final mediaType = rev['media_type']?.toString() ?? '';
                final rawMediaUrl = rev['media_url']?.toString() ?? '';
                final resolvedMediaUrl = AppConfig.fileUrl(rawMediaUrl);

                return Container(
                  margin: EdgeInsets.only(bottom: idx == latestReviews.length - 1 ? 0 : 12),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${rev['customer'] ?? 'Pelanggan'} · ${rev['item_name'] ?? 'Produk'}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (rev['tanggal'] != null) ...[
                        const SizedBox(height: 2),
                        Text(rev['tanggal'].toString(), style: TextStyle(fontSize: 10.5, color: context.textMuted)),
                      ],
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          comment,
                          style: TextStyle(fontSize: 12.5, color: context.textSecondary, height: 1.4),
                        ),
                      ],
                      if (resolvedMediaUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        if (mediaType == 'video')
                          GestureDetector(
                            onTap: () => _openVideoDialog(resolvedMediaUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Putar Video Ulasan',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => FullscreenImageViewer.show(context, resolvedMediaUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                resolvedMediaUrl,
                                width: 88,
                                height: 88,
                                cacheWidth: 600,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }),
            ),
    );
  }
}
