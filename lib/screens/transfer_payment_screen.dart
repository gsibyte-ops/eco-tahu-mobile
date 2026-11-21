import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import '../utils/media_validator.dart';
import 'order_success_screen.dart';

class TransferPaymentScreen extends StatefulWidget {
  final Order order;

  const TransferPaymentScreen({super.key, required this.order});

  @override
  State<TransferPaymentScreen> createState() => _TransferPaymentScreenState();
}

class _TransferPaymentScreenState extends State<TransferPaymentScreen> {
  Timer? _timer;
  int _remainingSeconds = 24 * 60 * 60; // 24 jam

  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isUploaded = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _formattedTime {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label berhasil disalin!'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final err = MediaValidator.validateImageFile(image.name, bytes.length, maxBytes: 4 * 1024 * 1024);
        if (err != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Provider.of<OrderProvider>(context, listen: false)
          .updateOrderStatus(widget.order.orderNumber, 'Menunggu Verifikasi');
      setState(() {
        _isUploading = false;
        _isUploaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Bukti transfer berhasil dikirim!'),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String bankName = widget.order.paymentMethod.contains('(')
        ? widget.order.paymentMethod.split('(')[1].replaceAll(')', '')
        : 'Bank';

    String vaNumber =
        "8888${widget.order.orderNumber.length >= 8 ? widget.order.orderNumber.substring(widget.order.orderNumber.length - 8) : widget.order.orderNumber}";

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark ? AppTheme.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Pembayaran Transfer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: context.isDark ? 0.06 : 0.12),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: context.isDark ? 0.04 : 0.08),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Icon
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pesanan Siap Dibayar!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selesaikan transfer sebelum batas waktu habis',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Countdown Timer Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : Colors.red.shade50.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.isDark ? const Color(0xFFDC2626).withOpacity(0.4) : Colors.red.shade200.withValues(alpha: 0.8)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer_outlined, color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'BATAS WAKTU PEMBAYARAN',
                                style: TextStyle(
                                  color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red.shade800,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Glass VA Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF047857), Color(0xFF065F46)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$bankName Virtual Account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bankName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nomor Virtual Account',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vaNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: 2,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copyToClipboard(vaNumber, 'Nomor Virtual Account'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 5),
                                    Text('Salin', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pembayaran',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(widget.order.totalPrice),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copyToClipboard(widget.order.totalPrice.toString(), 'Nominal Transfer'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy_rounded, color: Colors.white70, size: 12),
                                    SizedBox(width: 4),
                                    Text('Salin Nominal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order Summary Glass Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: context.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kode Pesanan', style: TextStyle(fontSize: 11, color: context.textSecondary)),
                                  Text(
                                    widget.order.orderNumber,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.isDark ? const Color(0xFF78350F).withOpacity(0.3) : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.isDark ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.orange.shade200),
                                ),
                                child: Text(
                                  'Menunggu Bayar',
                                  style: TextStyle(color: context.isDark ? const Color(0xFFFCD34D) : Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24, color: context.border),
                          _buildRowText('Tanggal', widget.order.formattedDate),
                          const SizedBox(height: 8),
                          _buildRowText('Metode Bayar', widget.order.paymentMethod),
                          const SizedBox(height: 8),
                          _buildRowText('Tipe Pengiriman', widget.order.pickupMethod),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Upload Bukti Glass Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.emeraldDarkSoft.withValues(alpha: 0.25) : const Color(0xFFF0FDF4).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF059669), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Upload Bukti Transfer',
                                style: TextStyle(
                                  color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF064E3B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unggah struk atau screenshot bukti transfer agar admin dapat langsung memverifikasi.',
                            style: TextStyle(color: context.textSecondary, fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 14),

                          // File picker capsule
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isUploaded ? null : _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: context.isDark ? AppTheme.darkSurfaceElevated : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedImage == null ? Icons.attach_file_rounded : Icons.image_rounded,
                                      color: const Color(0xFF059669),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedImage == null ? 'Pilih foto dari galeri' : _selectedImage!.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedImage == null ? context.textMuted : (context.isDark ? AppTheme.emeraldLight : const Color(0xFF064E3B)),
                                          fontWeight: _selectedImage == null ? FontWeight.normal : FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _selectedImage == null ? 'Pilih' : 'Ganti',
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Submit upload button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: (_selectedImage == null || _isUploading || _isUploaded)
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: (_selectedImage == null || _isUploading || _isUploaded)
                                  ? (context.isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade300)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: (_selectedImage == null || _isUploading || _isUploaded)
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton(
                              onPressed: (_selectedImage == null || _isUploading || _isUploaded) ? null : _handleUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: context.isDark ? AppTheme.darkTextMuted : Colors.grey.shade600,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isUploaded ? 'Bukti Terkirim' : 'Kirim Bukti Transfer',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => OrderSuccessScreen(order: widget.order)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Detail Pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textPrimary,
                          side: BorderSide(color: context.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: context.cardBg,
                        ),
                        child: Text('Beranda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimary)),
      ],
    );
  }
}
