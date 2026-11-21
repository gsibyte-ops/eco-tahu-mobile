import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HowToOrderScreen extends StatelessWidget {
  const HowToOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'num': '1',
        'title': 'Pilih Produk',
        'desc': 'Buka halaman Beranda atau Katalog Produk, pilih tahu segar atau produk olahan limbah (ampas tahu) yang Anda inginkan.',
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'num': '2',
        'title': 'Tambah ke Keranjang',
        'desc': 'Tentukan jumlah pesanan (kg / pcs), lalu tekan tombol "Tambah ke Keranjang".',
        'icon': Icons.add_shopping_cart,
      },
      {
        'num': '3',
        'title': 'Periksa Keranjang Belanja',
        'desc': 'Buka ikon Keranjang untuk memastikan seluruh rincian dan kuantitas produk sudah sesuai.',
        'icon': Icons.shopping_cart_outlined,
      },
      {
        'num': '4',
        'title': 'Isi Data Checkout & Alamat',
        'desc': 'Pilih metode pengiriman: Ambil Sendiri (Pickup Gratis) atau Diantar ke Rumah dengan pin lokasi peta otomatis.',
        'icon': Icons.location_on_outlined,
      },
      {
        'num': '5',
        'title': 'Pilih Metode Pembayaran',
        'desc': 'Pilih metode pembayaran yang tersedia: Bayar di Tempat (COD) atau Transfer Virtual Account (BCA, BRI, Mandiri, BNI).',
        'icon': Icons.payment_outlined,
      },
      {
        'num': '6',
        'title': 'Konfirmasi & Bayar',
        'desc': 'Selesaikan pesanan. Jika memilih Transfer, unggah foto bukti transfer di halaman detail pesanan.',
        'icon': Icons.receipt_long_outlined,
      },
      {
        'num': '7',
        'title': 'Pesanan Diproses & Diantar',
        'desc': 'Admin memverifikasi pesanan Anda dan kurir toko mengantarkan tahu segar langsung ke alamat tujuan.',
        'icon': Icons.local_shipping_outlined,
      },
    ];

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
          'Cara Pesan',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Mudah Memesan di EcoTahu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Ikuti 7 langkah praktis ini untuk memesan produk tahu segar & limbah ampas tahu pilihan:',
              style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = steps[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s['num'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(s['icon'] as IconData, size: 18, color: AppTheme.primaryGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    s['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s['desc'] as String,
                              style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
