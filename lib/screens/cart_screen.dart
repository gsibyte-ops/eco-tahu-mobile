import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/store_provider.dart';
import 'checkout_screen.dart';
import '../widgets/auth_guard.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // === FUNGSI UNTUK WHATSAPP ===
  Future<void> _checkoutViaWhatsApp(CartProvider cart) async {
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'melakukan pemesanan via WhatsApp',
    );
    if (!canProceed || !mounted) return;

    final store = Provider.of<StoreProvider>(context, listen: false);
    if (!store.isLoaded) {
      await store.loadStoreInfo();
    }

    String pesan = "Halo Admin EcoTahu, saya ingin memesan produk:\n\n";

    for (var item in cart.items) {
      pesan += "• ${item.product.name} (${item.quantity} ${item.product.satuan}) - ${formatCurrency(item.product.priceValue * item.quantity)}\n";
    }

    pesan += "\n*Total Belanja: ${formatCurrency(cart.subtotal)}*\n\nMohon konfirmasi ketersediaan dan ongkos kirimnya. Terima kasih!";

    final Uri url = store.buildWhatsAppUri(pesan);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka WhatsApp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // === MODAL PILIHAN CHECKOUT MODERN ===
  void _showCheckoutOptions(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: BoxDecoration(
                color: context.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: context.border, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Pilih Cara Checkout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih kemudahan proses pemesanan yang Anda inginkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: context.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Opsi 1: Checkout di Aplikasi (Rekomendasi)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: context.isDark
                              ? [AppTheme.emeraldDarkSoft, const Color(0xFF065F46).withValues(alpha: 0.45)]
                              : const [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF86EFAC),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Checkout di Aplikasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF065F46),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 13, color: context.brandGreen),
                                        const SizedBox(width: 2),
                                        Text('Cepat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.brandGreen)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Pilih pin peta, hitung ongkir otomatis, bayar COD / Transfer.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.isDark ? AppTheme.darkTextSecondary : const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 15, color: context.brandGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opsi 2: WhatsApp
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _checkoutViaWhatsApp(cart);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pesan via WhatsApp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Hubungkan pesanan langsung ke chat customer service kami.',
                                  style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 15, color: context.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keranjang Belanja',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final isAdmin = context.watch<AuthProvider>().isAdmin;
          if (cart.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAdmin) ...[
                      _buildAdminReadOnlyBanner(context),
                      const SizedBox(height: 20),
                    ],
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.tahuTagBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_bag_outlined, size: 44, color: context.brandGreen),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Keranjang Kamu Masih Kosong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yuk mulai belanja tahu organik segar atau olahan ampas bernutrisi tinggi sekarang!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: context.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: const Text('Mulai Belanja', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                        shadowColor: const Color(0xFF059669).withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin) ...[
                      _buildAdminReadOnlyBanner(context),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.items.length} Macam Produk',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => cart.clearCart(),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFEF4444)),
                          label: const Text(
                            'Kosongkan',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // LIST ITEM DALAM KERANJANG
                    ...cart.items.map((item) {
                      final isLimbah = item.product.type == 'limbah';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Gambar Produk
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: item.product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrl,
                                      width: 76,
                                      height: 76,
                                      cacheWidth: 400,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 76,
                                        height: 76,
                                        color: isLimbah ? context.limbahTagBg : context.tahuTagBg,
                                        child: Center(
                                          child: Icon(
                                            isLimbah ? Icons.recycling_rounded : Icons.eco_rounded,
                                            size: 32,
                                            color: isLimbah ? context.brandAmber : context.brandGreen,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 76,
                                      height: 76,
                                      color: isLimbah ? context.limbahTagBg : context.tahuTagBg,
                                      child: Center(
                                        child: Icon(
                                          isLimbah ? Icons.recycling_rounded : Icons.eco_rounded,
                                          size: 32,
                                          color: isLimbah ? context.brandAmber : context.brandGreen,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),

                            // Deskripsi & Kontrol Jumlah
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.close_rounded, size: 18, color: context.textMuted),
                                        onPressed: () => cart.removeFromCart(item),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.product.price,
                                    style: TextStyle(color: context.textSecondary, fontSize: 11.5),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Quantity Controls
                                      Container(
                                        decoration: BoxDecoration(
                                          color: context.isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildQtyButton(Icons.remove_rounded, () => cart.decreaseQuantity(item)),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '${item.quantity}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                            ),
                                            _buildQtyButton(Icons.add_rounded, () => cart.increaseQuantity(item)),
                                          ],
                                        ),
                                      ),

                                      // Subtotal per Item
                                      Text(
                                        formatCurrency(item.product.priceValue * item.quantity),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: isLimbah ? const Color(0xFFD97706) : const Color(0xFF059669),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // RINGKASAN BELANJA CARD
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Pesanan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSummaryRow(
                            'Total Item',
                            '${cart.items.fold(0, (sum, item) => sum + item.quantity)} pcs/kg',
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryRow('Subtotal Produk', formatCurrency(cart.subtotal)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: context.border),
                          ),
                          _buildSummaryRow('Total Sementara', formatCurrency(cart.subtotal), isTotal: true),
                          const SizedBox(height: 6),
                          Text(
                            '* Ongkos kirim dihitung otomatis saat memilih alamat pengiriman.',
                            style: TextStyle(fontSize: 11, color: context.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // STICKY BOTTOM CHECKOUT BUTTON
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
                        color: context.surface.withValues(alpha: 0.94),
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
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Tagihan',
                                  style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  formatCurrency(cart.subtotal),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.brandGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final canProceed = await AuthGuard.requireAuth(
                                context,
                                actionMessage: 'melakukan checkout pesanan',
                              );
                              if (!canProceed || !context.mounted) return;
                              _showCheckoutOptions(cart);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.brandGreenSolid,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                              elevation: 3,
                              shadowColor: context.brandGreenSolid.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              children: [
                                Text('Lanjut Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminReadOnlyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.25)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode Pemantauan Admin (Read-Only): Admin hanya dapat melihat tampilan dan tidak dapat menambah produk atau checkout.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: context.isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: const Color(0xFF059669)),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            fontSize: isTotal ? 15 : 13,
            color: isTotal ? context.textPrimary : context.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: isTotal ? const Color(0xFF059669) : context.textPrimary,
            fontSize: isTotal ? 17 : 13.5,
          ),
        ),
      ],
    );
  }
}
