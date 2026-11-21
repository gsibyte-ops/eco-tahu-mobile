import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

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
          'Kebijakan Privasi',
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
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kebijakan Privasi EcoTahu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bagaimana kami menghargai dan melindungi data pribadi Anda.',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: context.border),
                  const SizedBox(height: 18),

                  _buildParagraph(
                    context: context,
                    title: '1. Data yang Kami Kumpulkan',
                    body: 'Kami hanya mengumpulkan data pribadi yang Anda berikan saat mendaftar dan checkout, seperti Nama Lengkap, Alamat Email, Nomor Telepon, Alamat Pengiriman, serta Titik Koordinat Peta Pengiriman.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '2. Penggunaan Informasi',
                    body: 'Data tersebut digunakan secara eksklusif untuk memproses pesanan, menghitung ongkos kirim secara akurat, menghubungi Anda terkait status pengantaran, dan memberikan layanan purna jual.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '3. Keamanan Data',
                    body: 'Kami berkomitmen menjaga keamanan informasi pribadi Anda. Kata sandi dienkripsi dengan algoritma hashing standar industri (Bcrypt). Kami tidak pernah menjual atau membagikan data Anda kepada pihak ketiga untuk kepentingan iklan.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '4. Hak Pengguna & Hapus Akun',
                    body: 'Anda memiliki hak penuh untuk memperbarui profil Anda sewaktu-waktu atau menghapus akun dan data pribadi Anda secara permanen melalui fitur Hapus Akun di menu Profil.',
                  ),
                  const SizedBox(height: 16),

                  _buildParagraph(
                    context: context,
                    title: '5. Kontak Privasi',
                    body: 'Jika Anda memiliki pertanyaan seputar perlindungan data dan privasi di aplikasi EcoTahu, silakan hubungi tim kami melalui email ${store.email} atau WhatsApp resmi kami di ${store.whatsappDisplay}.',
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
