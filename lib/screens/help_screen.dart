import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<StoreProvider>(context, listen: false).loadStoreInfo(force: true);
    });
  }

  Future<void> _launchExternal(Uri url, String errorLabel) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Cannot open $url');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka $errorLabel pada perangkat ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          'Pusat Bantuan',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.darkGreen, Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Butuh Bantuan?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tim CS EcoTahu siap membantu pertanyaan, kendala pesanan, atau informasi produk.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _launchExternal(
                      store.buildWhatsAppUri('Halo Admin EcoTahu, saya butuh bantuan.'),
                      'WhatsApp',
                    ),
                    icon: const Icon(Icons.chat, size: 18, color: AppTheme.darkGreen),
                    label: const Text(
                      'Chat WhatsApp Admin',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Kontak & Lokasi
            Text(
              'Kontak & Operasional',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  _buildContactTile(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'WhatsApp Customer Service',
                    value: store.whatsappDisplay,
                    onTap: () => _launchExternal(
                      store.buildWhatsAppUri('Halo Admin EcoTahu, saya butuh bantuan.'),
                      'WhatsApp',
                    ),
                  ),
                  Divider(height: 1, indent: 60, color: context.border),
                  _buildContactTile(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Email Resmi',
                    value: store.email,
                    onTap: () => _launchExternal(
                      store.buildEmailUri(subject: 'Bantuan EcoTahu'),
                      'aplikasi Email',
                    ),
                  ),
                  Divider(height: 1, indent: 60, color: context.border),
                  _buildContactTile(
                    context: context,
                    icon: Icons.access_time_outlined,
                    title: 'Jam Operasional',
                    value: store.jamOperasional,
                  ),
                  Divider(height: 1, indent: 60, color: context.border),
                  _buildContactTile(
                    context: context,
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Alamat ${store.nama}',
                    value: store.alamat,
                    onTap: () => _launchExternal(store.buildMapsUri(), 'Google Maps'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Media Sosial Resmi
            Text(
              'Media Sosial Resmi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  _buildContactTile(
                    context: context,
                    icon: Icons.camera_alt_outlined,
                    title: 'Instagram',
                    value: store.instagramLabel,
                    onTap: () => _launchExternal(Uri.parse(store.instagramUrl), 'Instagram'),
                  ),
                  Divider(height: 1, indent: 60, color: context.border),
                  _buildContactTile(
                    context: context,
                    icon: Icons.music_note_rounded,
                    title: 'TikTok',
                    value: store.tiktokLabel,
                    onTap: () => _launchExternal(Uri.parse(store.tiktokUrl), 'TikTok'),
                  ),
                  Divider(height: 1, indent: 60, color: context.border),
                  _buildContactTile(
                    context: context,
                    icon: Icons.facebook_rounded,
                    title: 'Facebook',
                    value: store.facebookLabel,
                    onTap: () => _launchExternal(Uri.parse(store.facebookUrl), 'Facebook'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // FAQ Ringkas
            Text(
              'Pertanyaan Populer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildFaqCard(
              context: context,
              q: 'Bagaimana cara memesan tahu?',
              a: 'Pilih produk di katalog, masukkan ke keranjang, lalu klik Checkout dan pilih metode pembayaran.',
            ),
            const SizedBox(height: 10),
            _buildFaqCard(
              context: context,
              q: 'Bagaimana cara melacak pengiriman kurir?',
              a: 'Buka menu Pesanan Saya di Profil, pilih pesanan yang berstatus "Dikirim", lalu klik tombol "Lacak Posisi Kurir".',
            ),
            const SizedBox(height: 10),
            _buildFaqCard(
              context: context,
              q: 'Kapan tahu diproduksi?',
              a: 'Tahu diproduksi segar setiap pagi langsung dari kedelai pilihan tanpa bahan kimia pengawet.',
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.lightGreen.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 12, color: context.textSecondary)),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
      ),
      trailing: onTap != null ? Icon(Icons.chevron_right, color: context.textSecondary, size: 20) : null,
    );
  }

  Widget _buildFaqCard({required BuildContext context, required String q, required String a}) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 14)),
              Expanded(
                child: Text(
                  q,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              a,
              style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
