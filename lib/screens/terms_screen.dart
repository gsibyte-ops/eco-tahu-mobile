import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Syarat & Ketentuan',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Syarat & Ketentuan Layanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terakhir diperbarui: November 2026',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: context.border),
                  const SizedBox(height: 18),

                  _buildParagraph(
                    context: context,
                    title: '1. Penerimaan Ketentuan',
                    body: 'Dengan mengunduh, mengakses, dan menggunakan aplikasi EcoTahu, Anda menyatakan setuju untuk terikat secara hukum oleh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui salah satu poin, harap untuk tidak melanjutkan penggunaan layanan kami.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '2. Akun dan Keamanan',
                    body: 'Anda bertanggung jawab penuh untuk menjaga kerahasiaan kata sandi akun dan data login Anda. EcoTahu tidak bertanggung jawab atas segala kerugian yang diakibatkan oleh kelalaian pengguna dalam menjaga keamanan akun miliknya.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '3. Pemesanan dan Harga',
                    body: 'Semua pesanan produk tahu maupun produk limbah ampas tahu bergantung pada ketersediaan stok harian. Harga yang tercantum dapat berubah sewaktu-waktu sesuai dengan fluktuasi harga bahan baku kedelai tanpa pemberitahuan sebelumnya.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '4. Pembayaran dan Verifikasi',
                    body: 'Untuk metode Transfer Virtual Account, pembayaran wajib diselesaikan maksimal dalam 24 jam sebelum batas kedaluwarsa. Bukti transfer yang diunggah akan diverifikasi oleh admin toko sebelum pesanan diteruskan ke kurir.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '5. Pembatalan dan Pengembalian',
                    body: 'Pesanan yang sudah dibayar tidak dapat dibatalkan secara sepihak jika sudah dalam tahap pengiriman. Pembatalan pesanan hanya diperkenankan saat status masih Pending atau Diproses, dan tunduk pada Kebijakan Refund kami.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '6. Sanksi Pelanggaran',
                    body: 'Setiap tindakan penipuan, unggahan bukti palsu, pembuatan pesanan fiktif, atau penyalahgunaan akun akan ditindak tegas dengan pemblokiran akun secara permanen.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph({required BuildContext context, required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}
