import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';
import '../services/api_service.dart';
import '../services/local_cache_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/shimmer_skeletons.dart';
import '../services/secure_storage_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Pending', 'Diproses', 'Dikirim', 'Selesai', 'Dibatalkan'];

  bool _isLoading = true;
  List<Order> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final token = await SecureStorageService.readToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Silakan login terlebih dahulu untuk melihat pesanan.';
        });
      }
      return;
    }

    // 1. Tampilkan cache lokal secara instan (offline-first seperti GoPay/Shopee)
    bool hasLocalCache = false;
    final cachedRaw = await LocalCacheService.readJson(LocalCacheService.keyOrders);
    if (cachedRaw is List) {
      final cachedOrders = cachedRaw
          .whereType<Map>()
          .map((json) => Order.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      hasLocalCache = true;
      if (mounted) {
        setState(() {
          _orders = cachedOrders;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    }

    // 2. Refresh live dari server (jika offline, pertahankan data cache lokal)
    final data = await ApiService().getOrders(token);

    if (mounted) {
      setState(() {
        if (data != null) {
          _orders = data
              .whereType<Map>()
              .map((json) => Order.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _errorMessage = null;
        } else if (!hasLocalCache && _orders.isEmpty) {
          _errorMessage = 'Anda sedang offline dan belum ada riwayat pesanan yang tersimpan di perangkat ini. Hubungkan internet lalu tekan Muat Ulang.';
        }
        _isLoading = false;
      });
    }
  }

  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _showCancelDialog(Order order) {
    final TextEditingController reasonController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isValid = reasonController.text.trim().length >= 10;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Batalkan Pesanan',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.limbahTagBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.limbahTagBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: context.brandAmber, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Setelah dibatalkan, status pesanan tidak dapat dikembalikan ke semula.',
                                    style: TextStyle(color: context.limbahTagText, fontSize: 12, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Alasan Pembatalan *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: context.isDark ? AppTheme.emeraldBright : const Color(0xFF064E3B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: reasonController,
                            maxLines: 3,
                            onChanged: (val) => setStateDialog(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Minimal 10 karakter alasan...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Batal', style: TextStyle(color: Colors.black87)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (isValid && !isProcessing)
                                      ? () async {
                                          setStateDialog(() => isProcessing = true);

                                          final token = (await SecureStorageService.readToken()) ?? '';

                                          final res = await ApiService().cancelOrder(
                                            token: token,
                                            pesananId: order.id,
                                            alasan: reasonController.text.trim(),
                                          );

                                          setStateDialog(() => isProcessing = false);

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message'] ?? 'Pesanan dibatalkan'),
                                                backgroundColor: res['success'] == true ? const Color(0xFFDC2626) : Colors.black87,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                            _fetchOrders();
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'Semua') return true;
      return order.status.toLowerCase().replaceAll('_', ' ') == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark ? AppTheme.darkSurface.withOpacity(0.85) : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: 0.08),
              ),
            ),
          ),

          Column(
            children: [
              const OfflineStatusBanner(),
              Expanded(
                child: _isLoading
                    ? const OrderListShimmerSkeleton()
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.grey, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchOrders,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                    child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                      color: const Color(0xFF059669),
                      onRefresh: _fetchOrders,
                      child: Column(
                        children: [
                          // Filter horizontal bar
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filters.length,
                              itemBuilder: (context, index) {
                                final filter = _filters[index];
                                final isSelected = _selectedFilter == filter;
                                final count = filter == 'Semua'
                                    ? _orders.length
                                    : _orders
                                        .where((o) => o.status.toLowerCase().replaceAll('_', ' ') == filter.toLowerCase())
                                        .length;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedFilter = filter),
                                      borderRadius: BorderRadius.circular(16),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isSelected ? null : context.cardBg,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : context.border,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? const Color(0xFF059669).withValues(alpha: 0.25)
                                                  : Colors.black.withOpacity(context.isDark ? 0.2 : 0.02),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$filter ($count)',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : context.textSecondary,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // List Pesanan
                          Expanded(
                            child: filteredOrders.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 36),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Tidak ada pesanan $_selectedFilter',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pesanan belanja Anda akan tercatat di sini.',
                                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    itemCount: filteredOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = filteredOrders[index];
                                      return _buildOrderCard(order);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    String statusLower = order.status.toLowerCase().replaceAll('_', ' ');
    bool canCancel = statusLower == 'pending' || statusLower == 'diproses';

    Color badgeBg = context.isDark ? const Color(0xFF78350F).withOpacity(0.3) : Colors.amber.shade50;
    Color badgeBorder = context.isDark ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.amber.shade200;
    Color badgeText = context.isDark ? const Color(0xFFFCD34D) : Colors.amber.shade900;

    if (statusLower == 'dibatalkan') {
      badgeBg = context.isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : Colors.red.shade50;
      badgeBorder = context.isDark ? const Color(0xFFDC2626).withOpacity(0.4) : Colors.red.shade200;
      badgeText = context.isDark ? const Color(0xFFFCA5A5) : Colors.red.shade800;
    } else if (statusLower == 'selesai') {
      badgeBg = context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4);
      badgeBorder = context.isDark ? AppTheme.emeraldLight.withOpacity(0.4) : const Color(0xFF10B981).withValues(alpha: 0.4);
      badgeText = context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669);
    } else if (statusLower == 'dikirim') {
      badgeBg = context.isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF);
      badgeBorder = context.isDark ? const Color(0xFF3B82F6).withOpacity(0.4) : const Color(0xFF93C5FD);
      badgeText = context.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
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
                  color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header: Order Number & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nomor Pesanan', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          order.orderNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Text(
                        order.status.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tanggal: ${order.formattedDate}',
                  style: TextStyle(color: context.textMuted, fontSize: 11),
                ),
                Divider(height: 22, color: context.border),

                // Product details row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.tahuTagBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.tahuTagBorder),
                      ),
                      child: Center(
                        child: Icon(Icons.eco_rounded, color: context.brandGreen, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.productName} × ${order.quantity} kg',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.paymentMethod} · ${order.pickupMethod}',
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(order.totalPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.brandGreen,
                      ),
                    ),
                  ],
                ),
                Divider(height: 22, color: context.border),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canCancel) ...[
                      OutlinedButton(
                        onPressed: () => _showCancelDialog(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFF87171)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: context.isDark ? AppTheme.dangerDarkSoft : Colors.red.shade50.withValues(alpha: 0.5),
                        ),
                        child: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
                          );
                          _fetchOrders();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Lihat Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
