import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';

class ShippingInfoScreen extends StatelessWidget {
  const ShippingInfoScreen({super.key});

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final maxRadius = store.radiusMaksKm % 1 == 0
        ? store.radiusMaksKm.toStringAsFixed(0)
        : store.radiusMaksKm.toString();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Informasi Pengiriman',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                              : AppTheme.lightGreen.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping, color: AppTheme.primaryGreen, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Same-Day Delivery',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Khusus Area Kabupaten Jember',
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kami melayani pengiriman langsung dari pabrik dengan kurir toko sendiri untuk memastikan kualitas tahu tetap segar sampai di tangan Anda.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Ketentuan & Jangkauan Pengiriman',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 12),

            _buildDetailCard(
              context: context,
              icon: Icons.radar,
              title: 'Radius Maksimal',
              desc: 'Maksimal $maxRadius km dari lokasi pabrik/toko kami (${store.alamat}).',
            ),
            const SizedBox(height: 10),

            _buildDetailCard(
              context: context,
              icon: Icons.calculate_outlined,
              title: 'Perhitungan Ongkir Otomatis',
              desc: 'Tarif minimal ${_formatRp(store.ongkirMinimal)} (0–2 km), selanjutnya ${_formatRp(store.ongkirPerKm)}/km berdasarkan jarak koordinat toko ke pin lokasi peta Anda.',
            ),
            const SizedBox(height: 10),

            _buildDetailCard(
              context: context,
              icon: Icons.monetization_on_outlined,
              title: 'Minimal Pembelian Delivery',
              desc: 'Minimal belanja ${_formatRp(store.minimalDelivery)} untuk layanan pengantaran (Delivery).',
            ),
            const SizedBox(height: 10),

            _buildDetailCard(
              context: context,
              icon: Icons.storefront_outlined,
              title: 'Ambil di Toko (Pickup)',
              desc: 'Gratis ongkos kirim (Rp 0) tanpa batasan minimum belanja jika Anda memilih opsi Ambil di Tempat.',
            ),
            const SizedBox(height: 10),

            _buildDetailCard(
              context: context,
              icon: Icons.schedule_outlined,
              title: 'Jadwal Antar',
              desc: 'Pengantaran dilakukan setiap hari dalam 2 sesi: Pagi (07.00 - 10.00 WIB) & Siang (13.00 - 16.00 WIB).',
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                  : AppTheme.lightGreen.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
