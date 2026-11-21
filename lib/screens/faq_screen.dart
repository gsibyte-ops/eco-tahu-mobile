import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expandedIndex;

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final maxRadius = store.radiusMaksKm % 1 == 0
        ? store.radiusMaksKm.toStringAsFixed(0)
        : store.radiusMaksKm.toString();

    final faqs = [
      {
        'q': 'Apakah tahu EcoTahu 100% organik?',
        'a': 'Ya, kami menggunakan kedelai non-GMO pilihan kualitas premium tanpa bahan pengawet sintetis dan tanpa pewarna kimia buatan.',
      },
      {
        'q': 'Apa itu produk limbah (ampas tahu)?',
        'a': 'Produk limbah adalah olahan bernilai tinggi dari ampas tahu yang kami proses higienis menjadi pakan ternak berprotein tinggi, pupuk organik, serta olahan pangan ramah lingkungan untuk mendukung konsep Zero Waste.',
      },
      {
        'q': 'Bisa bayar di tempat (COD)?',
        'a': 'Sangat bisa! Anda cukup memilih metode COD saat checkout, dan pembayaran diserahkan langsung saat kurir mengantarkan pesanan.',
      },
      {
        'q': 'Bagaimana cara membatalkan pesanan?',
        'a': 'Anda dapat membatalkan pesanan yang masih berstatus Pending atau Diproses melalui menu Pesanan Saya, dengan memasukkan alasan pembatalan minimal 10 karakter.',
      },
      {
        'q': 'Berapa lama masa simpan tahu segar?',
        'a': 'Tahu segar kami bertahan 2–3 hari di suhu ruangan sejuk, dan hingga 7–10 hari jika direndam air bersih di dalam kulkas (ganti air rendaman setiap 1–2 hari).',
      },
      {
        'q': 'Apakah ada minimal pembelian?',
        'a': 'Untuk layanan pesan antar (Delivery), minimal belanja adalah ${_formatRp(store.minimalDelivery)}. Untuk ambil sendiri di pabrik (Pickup), tidak ada minimal pembelian.',
      },
      {
        'q': 'Berapa radius pengiriman kurir?',
        'a': 'Maksimal radius $maxRadius km dari lokasi pabrik kami (${store.alamat}). Tarif ongkir minimal ${_formatRp(store.ongkirMinimal)} (0–2 km) dan selanjutnya ${_formatRp(store.ongkirPerKm)}/km.',
      },
      {
        'q': 'Bagaimana cara memberi ulasan produk?',
        'a': 'Setelah pesanan berstatus Selesai, buka detail pesanan tersebut dan klik tombol "Beri Ulasan & Rating" untuk membagikan pengalaman Anda.',
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
          'Tanya Jawab (FAQ)',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final isExpanded = _expandedIndex == index;
          final faq = faqs[index];

          return Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? AppTheme.primaryGreen : context.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? AppTheme.primaryGreen
                                : (context.isDark
                                    ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                                    : AppTheme.lightGreen.withValues(alpha: 0.4)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_outline,
                            size: 16,
                            color: isExpanded ? Colors.white : AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            faq['q']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isExpanded ? AppTheme.primaryGreen : context.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, color: context.border),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          faq['a']!,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
