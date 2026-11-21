import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'my_orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Ambient Glow Blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: context.isDark ? 0.08 : 0.15),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: context.isDark ? 0.05 : 0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),

                  // Animated/Glow Checkmark Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                      ),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title & Subtitle
                  Text(
                    'Pesanan Berhasil Dibuat!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terima kasih sudah mendukung produk organik & zero-waste EcoTahu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Glassmorphic Receipt Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ringkasan Pesanan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'Detail',
                                    style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 26, color: context.border),
                            _buildRow(context, 'Nomor Pesanan', order.orderNumber, isHighlight: true),
                            const SizedBox(height: 12),
                            _buildRow(context, 'Produk', '${order.productName} × ${order.quantity} kg'),
                            const SizedBox(height: 12),
                            _buildRow(context, 'Metode Pengambilan', order.pickupMethod),
                            const SizedBox(height: 12),
                            _buildRow(context, 'Metode Pembayaran', order.paymentMethod),
                            const SizedBox(height: 12),
                            _buildRow(context, 'Status', order.status, isStatus: true),
                            if (order.discount > 0) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Diskon Order Pertama',
                                    style: TextStyle(
                                      color: context.brandGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '-${formatCurrency(order.discount)}',
                                    style: TextStyle(
                                      color: context.brandGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            Divider(height: 28, color: context.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pembayaran',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                                ),
                                Text(
                                  formatCurrency(order.totalPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark ? AppTheme.emeraldDarkSoft.withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status pesanan dan lacak pengiriman kurir dapat dipantau langsung di halaman Pesanan Saya.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Primary Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                          (route) => false,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lihat Pesanan Saya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Outlined Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: context.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: context.cardBg,
                      ),
                      child: Text(
                        'Kembali ke Beranda',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {bool isHighlight = false, bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
              color: isStatus
                  ? (context.isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706))
                  : (isHighlight ? (context.isDark ? AppTheme.emeraldLight : const Color(0xFF064E3B)) : context.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
