import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/cart_provider.dart';

/// Banner peringatan global untuk mode offline & konfirmasi sinkronisasi ulang
/// saat internet kembali aktif (tampil untuk Guest, Pelanggan, maupun Admin).
class OfflineStatusBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const OfflineStatusBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final cart = context.watch<CartProvider>();

    if (conn.isOnline && !conn.justReconnected && !cart.hasPendingSync) {
      return const SizedBox.shrink();
    }

    // 1. Sedang Offline
    if (conn.isOffline) {
      final pendingText = cart.hasPendingSync
          ? ' · Keranjang disimpan lokal & akan disinkronkan saat online'
          : ' · Menampilkan data tersimpan';
      return _buildBannerContainer(
        context: context,
        bgColor: const Color(0xFF92400E),
        borderColor: const Color(0xFFF59E0B),
        icon: Icons.wifi_off_rounded,
        title: 'Anda sedang Offline',
        subtitle: 'Beberapa fitur realtime tidak tersedia$pendingText',
        actionLabel: 'Cek',
        onAction: () => conn.checkNow(),
      );
    }

    // 2. Baru saja kembali online / sedang menyinkronkan keranjang offline
    if (conn.justReconnected || cart.hasPendingSync) {
      return _buildBannerContainer(
        context: context,
        bgColor: const Color(0xFF065F46),
        borderColor: const Color(0xFF10B981),
        icon: Icons.cloud_done_rounded,
        title: cart.hasPendingSync ? 'Menyinkronkan keranjang ke server...' : 'Kembali Online!',
        subtitle: cart.hasPendingSync
            ? 'Perubahan keranjang saat offline sedang dikirim ke server.'
            : 'Koneksi pulih. Data terbaru siap dimuat.',
        actionLabel: cart.hasPendingSync ? 'Sinkronkan' : null,
        onAction: cart.hasPendingSync ? () => cart.syncWithServer() : null,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBannerContainer({
    required BuildContext context,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        margin: margin ?? const EdgeInsets.fromLTRB(14, 6, 14, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog / SnackBar helper saat user mencoba melakukan aksi yang wajib online (mis. Checkout / Komentar).
void showOfflineActionAlert(BuildContext context, {String? actionLabel}) {
  final text = actionLabel != null
      ? 'Fitur $actionLabel membutuhkan koneksi internet aktif.'
      : 'Anda sedang offline. Aktifkan internet untuk melanjutkan.';
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB45309),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
}
