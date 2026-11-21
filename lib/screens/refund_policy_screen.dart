import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

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
          'Kebijakan Refund',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.shield_outlined, color: Colors.orange.shade600, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Garansi Kualitas & Refund',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Perlindungan Belanja Produk Segar',
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kepuasan pelanggan adalah prioritas utama kami. Karena produk tahu adalah makanan segar tanpa pengawet sintetis, kami memberlakukan ketentuan khusus terkait refund (pengembalian dana):',
                    style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Syarat & Ketentuan Pengembalian Dana',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 12),

            _buildRuleCard(
              context: context,
              number: '1',
              title: 'Pesanan Dibatalkan',
              desc: 'Pengembalian dana penuh (100%) berlaku jika pesanan Transfer dibatalkan sebelum diproses atau jika stok produk habis.',
            ),
            const SizedBox(height: 10),

            _buildRuleCard(
              context: context,
              number: '2',
              title: 'Produk Basi atau Rusak',
              desc: 'Wajib menyertakan foto dan video unboxing saat paket diterima, diajukan maksimal 1x24 jam sejak pesanan diserahkan.',
            ),
            const SizedBox(height: 10),

            _buildRuleCard(
              context: context,
              number: '3',
              title: 'Metode COD',
              desc: 'Untuk pesanan COD yang dibatalkan atau ditolak saat kurir tiba, pembeli tidak dikenakan biaya pengembalian.',
            ),
            const SizedBox(height: 10),

            _buildRuleCard(
              context: context,
              number: '4',
              title: 'Waktu Pengembalian Dana',
              desc: 'Dana akan ditransfer kembali ke rekening pembeli maksimal 1–3 hari kerja setelah pengajuan disetujui oleh admin toko.',
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required BuildContext context,
    required String number,
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppTheme.primaryGreen.withOpacity(0.15)
                  : AppTheme.lightGreen.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
