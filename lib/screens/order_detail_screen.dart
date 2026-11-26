import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/media_validator.dart';
import '../widgets/auth_guard.dart';
import '../services/secure_storage_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isUploaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == 'Menunggu Verifikasi') {
      _isUploaded = true;
    }
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
        setState(() => _selectedImage = image);
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
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'mengupload bukti transfer',
    );
    if (!canProceed || !mounted) return;
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);

    final Uint8List fileBytes = await _selectedImage!.readAsBytes();
    final String fileName = _selectedImage!.name;

    final token = (await SecureStorageService.readToken()) ?? '';

    final result = await ApiService().uploadBuktiTransfer(
      token: token,
      pesananId: widget.order.id,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
    });

    if (result['success'] == true) {
      setState(() => _isUploaded = true);
      ApiService().getOrders(token);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Bukti transfer berhasil diupload!'),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengupload bukti'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'membatalkan pesanan',
    );
    if (!canProceed || !context.mounted) return;

    final TextEditingController reasonController = TextEditingController();
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController accNumberController = TextEditingController();
    final TextEditingController accNameController = TextEditingController();

    bool isProcessing = false;
    bool isTransferPayment = widget.order.paymentMethod.toLowerCase().contains('transfer');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isReasonValid = reasonController.text.trim().length >= 10;
            bool canSubmit = isReasonValid;

            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Batalkan Pesanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(widget.order.orderNumber, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.isDark ? const Color(0xFF78350F).withOpacity(0.2) : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.isDark ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.amber.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: context.isDark ? const Color(0xFFFCD34D) : Colors.amber.shade800, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Setelah dibatalkan, status pesanan tidak dapat dikembalikan ke semula.',
                                      style: TextStyle(color: context.isDark ? const Color(0xFFFCD34D) : Colors.amber.shade900, fontSize: 12, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Alasan Pembatalan *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: reasonController,
                              maxLines: 3,
                              onChanged: (val) => setStateDialog(() {}),
                              style: TextStyle(fontSize: 13, color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Minimal 10 karakter alasan...',
                                hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 12),
                                filled: true,
                                fillColor: context.isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFDC2626), width: 1.5)),
                              ),
                            ),
                            if (isTransferPayment) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.3) : const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryGreen, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Info Rekening Refund (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF064E3B))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: bankNameController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                                        LengthLimitingTextInputFormatter(50),
                                      ],
                                      style: TextStyle(fontSize: 12, color: context.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Nama Bank / E-Wallet (mis: BCA, Dana)',
                                        hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 11),
                                        isDense: true,
                                        filled: true,
                                        fillColor: context.isDark ? AppTheme.darkSurface : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: accNumberController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(30),
                                      ],
                                      style: TextStyle(fontSize: 12, color: context.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Nomor Rekening / HP Akun (khusus angka)',
                                        hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 11),
                                        isDense: true,
                                        filled: true,
                                        fillColor: context.isDark ? AppTheme.darkSurface : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: accNameController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                        LengthLimitingTextInputFormatter(100),
                                      ],
                                      style: TextStyle(fontSize: 12, color: context.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Nama Pemilik Rekening (hanya huruf)',
                                        hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 11),
                                        isDense: true,
                                        filled: true,
                                        fillColor: context.isDark ? AppTheme.darkSurface : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isProcessing ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: context.border),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Batal', style: TextStyle(color: context.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (canSubmit && !isProcessing)
                                        ? () async {
                                            setStateDialog(() => isProcessing = true);
                                            final token = (await SecureStorageService.readToken()) ?? '';

                                            final res = await ApiService().cancelOrder(
                                              token: token,
                                              pesananId: widget.order.id,
                                              alasan: reasonController.text.trim(),
                                              namaBank: bankNameController.text.trim().isNotEmpty ? bankNameController.text.trim() : null,
                                              nomorRekening: accNumberController.text.trim().isNotEmpty ? accNumberController.text.trim() : null,
                                              atasNama: accNameController.text.trim().isNotEmpty ? accNameController.text.trim() : null,
                                            );

                                            setStateDialog(() => isProcessing = false);

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(res['message'] ?? 'Pesanan dibatalkan'),
                                                  backgroundColor: res['success'] == true ? const Color(0xFFDC2626) : Colors.black87,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                              Navigator.pop(context); // Balik ke MyOrdersScreen
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: isProcessing
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReviewDialog(BuildContext context, [OrderItem? item]) async {
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'memberikan ulasan produk',
    );
    if (!canProceed || !context.mounted) return;

    int rating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;
    Uint8List? mediaBytes;
    String? mediaName;
    String? mediaKind;
    String? mediaError;

    final String itemName = item != null
        ? item.name
        : (widget.order.items.isNotEmpty ? widget.order.items.first.name : widget.order.productName);
    final int itemId = item != null
        ? item.itemId
        : (widget.order.items.isNotEmpty ? widget.order.items.first.itemId : 1);
    final String itemType = item != null
        ? (item.itemType == 'limbah' ? 'limbah' : 'produk')
        : (itemName.toLowerCase().contains('limbah') || itemName.toLowerCase().contains('ampas') ? 'limbah' : 'produk');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.isDark ? const Color(0xFF78350F).withOpacity(0.3) : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Beri Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
                                  Text(itemName, style: TextStyle(fontSize: 12, color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                                onPressed: () {
                                  setStateDialog(() => rating = index + 1);
                                },
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 13, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Ceritakan pengalaman kualitas produk dan layanan...',
                            hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 12),
                            filled: true,
                            fillColor: context.isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF059669), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Lampirkan Foto / Video (Opsional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        if (mediaBytes == null)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final picker = ImagePicker();
                                          final picked = await picker.pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1280,
                                            imageQuality: 80,
                                          );
                                          if (picked == null) return;
                                          final bytes = await picked.readAsBytes();
                                          final err = MediaValidator.validateImageFile(
                                            picked.name,
                                            bytes.length,
                                            maxBytes: MediaValidator.maxImageBytes,
                                          );
                                          setStateDialog(() {
                                            if (err != null) {
                                              mediaError = err;
                                            } else {
                                              mediaError = null;
                                              mediaBytes = bytes;
                                              mediaName = picked.name;
                                              mediaKind = 'image';
                                            }
                                          });
                                        },
                                  icon: const Icon(Icons.photo_camera_outlined, size: 16, color: Color(0xFF059669)),
                                  label: Text('Pilih Foto', style: TextStyle(fontSize: 12, color: context.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final picker = ImagePicker();
                                          final picked = await picker.pickVideo(
                                            source: ImageSource.gallery,
                                            maxDuration: const Duration(seconds: 60),
                                          );
                                          if (picked == null) return;
                                          final bytes = await picked.readAsBytes();
                                          final err = MediaValidator.validateVideoFile(
                                            picked.name,
                                            bytes.length,
                                          );
                                          setStateDialog(() {
                                            if (err != null) {
                                              mediaError = err;
                                            } else {
                                              mediaError = null;
                                              mediaBytes = bytes;
                                              mediaName = picked.name;
                                              mediaKind = 'video';
                                            }
                                          });
                                        },
                                  icon: const Icon(Icons.videocam_outlined, size: 17, color: Color(0xFF059669)),
                                  label: Text('Pilih Video', style: TextStyle(fontSize: 12, color: context.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Row(
                              children: [
                                if (mediaKind == 'image')
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(mediaBytes!, width: 48, height: 48, fit: BoxFit.cover),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF059669), size: 28),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mediaName ?? 'Media',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${(mediaBytes!.length / (1024 * 1024)).toStringAsFixed(1)} MB · ${mediaKind == 'video' ? 'Video' : 'Foto'}',
                                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setStateDialog(() {
                                      mediaBytes = null;
                                      mediaName = null;
                                      mediaKind = null;
                                      mediaError = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (mediaError != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              mediaError!,
                              style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.border),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Batal', style: TextStyle(color: context.textSecondary)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setStateDialog(() => isSubmitting = true);
                                          final token = (await SecureStorageService.readToken()) ?? '';

                                          final res = await ApiService().submitReview(
                                            token: token,
                                            pesananId: widget.order.id,
                                            reviewableType: itemType,
                                            reviewableId: itemId,
                                            rating: rating,
                                            komentar: commentController.text.trim(),
                                            mediaBytes: mediaBytes,
                                            mediaName: mediaName,
                                          );

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message'] ?? 'Ulasan berhasil dikirim!'),
                                                backgroundColor: res['success'] == true ? const Color(0xFF059669) : Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTrackingDialog(BuildContext context) async {
    final token = (await SecureStorageService.readToken()) ?? '';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateTracking) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: ApiService().getOrderTracking(token, widget.order.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF059669)),
                          SizedBox(height: 16),
                          Text('Menghubungkan ke GPS kurir...'),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                final bool active = data?['active'] == true;
                final kurir = data?['kurir'];
                final toko = data?['toko'];
                final tujuan = data?['tujuan'];
                final String liveCourierLabel =
                    data?['status_kurir_label']?.toString().trim().isNotEmpty == true
                        ? data!['status_kurir_label'].toString()
                        : widget.order.resolvedStatusKurirLabel;
                final int? liveEtaMin = int.tryParse(data?['estimasi_menit']?.toString() ?? '');
                final String? liveEtaWib = data?['estimasi_tiba_wib']?.toString();

                final store = Provider.of<StoreProvider>(context, listen: false);
                final double tokoLat = (toko?['lat'] as num?)?.toDouble() ?? store.lat;
                final double tokoLng = (toko?['lng'] as num?)?.toDouble() ?? store.lng;
                final LatLng storePoint = LatLng(tokoLat, tokoLng);

                final LatLng? kurirPoint = (kurir != null && kurir['lat'] != null)
                    ? LatLng((kurir['lat'] as num).toDouble(), (kurir['lng'] as num).toDouble())
                    : null;

                final LatLng? tujuanPoint = (tujuan != null && tujuan['lat'] != null)
                    ? LatLng((tujuan['lat'] as num).toDouble(), (tujuan['lng'] as num).toDouble())
                    : (widget.order.latitude != null && widget.order.longitude != null)
                        ? LatLng(widget.order.latitude!, widget.order.longitude!)
                        : null;

                LatLng centerPoint = kurirPoint ?? tujuanPoint ?? storePoint;

                List<Marker> markers = [];
                markers.add(
                  Marker(
                    point: storePoint,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 36),
                  ),
                );

                if (kurirPoint != null) {
                  markers.add(
                    Marker(
                      point: kurirPoint,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.delivery_dining, color: Color(0xFF2563EB), size: 36),
                    ),
                  );
                }

                if (tujuanPoint != null) {
                  markers.add(
                    Marker(
                      point: tujuanPoint,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFFD97706), size: 36),
                    ),
                  );
                }

                List<LatLng> polylinePoints = [storePoint];
                if (kurirPoint != null) polylinePoints.add(kurirPoint);
                if (tujuanPoint != null) polylinePoints.add(tujuanPoint);

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pelacakan Posisi Kurir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('Pesanan ${widget.order.orderNumber}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                tooltip: 'Perbarui Lokasi',
                                onPressed: () => setStateTracking(() {}),
                              ),
                            ],
                          ),
                        ),

                        // Interactive Leaflet Map
                        SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: centerPoint,
                              initialZoom: 14.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.ecotahumobile',
                              ),
                              if (polylinePoints.length >= 2)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: polylinePoints,
                                      strokeWidth: 3.5,
                                      color: const Color(0xFF059669).withValues(alpha: 0.8),
                                    ),
                                  ],
                                ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                        ),

                        // Info status box
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (active && kurirPoint != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.tahuTagBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: context.tahuTagBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.navigation_rounded, color: context.brandGreen, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Kurir Sedang Mengantar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: context.isDark ? AppTheme.emeraldBright : const Color(0xFF064E3B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Posisi kurir diperbarui secara live. Pantau pergerakan pada peta di atas.',
                                              style: TextStyle(fontSize: 11, color: context.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.limbahTagBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: context.limbahTagBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: context.brandAmber, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          liveEtaMin != null
                                              ? '$liveCourierLabel · Estimasi ±$liveEtaMin mnt${liveEtaWib != null ? ' (sekitar $liveEtaWib WIB)' : ''}'
                                              : liveCourierLabel,
                                          style: TextStyle(fontSize: 12, color: context.limbahTagText, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMapLegend(const Color(0xFF059669), 'Toko / Pabrik'),
                                  _buildMapLegend(const Color(0xFF2563EB), 'Kurir'),
                                  _buildMapLegend(const Color(0xFFD97706), 'Lokasi Anda'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCourierEtaCard(BuildContext context) {
    final order = widget.order;
    final bool isPickup = order.isPickupOrder;
    final List<Map<String, String>> steps = isPickup
        ? const [
            {'key': 'menyiapkan', 'label': 'Disiapkan'},
            {'key': 'siap_diambil', 'label': 'Siap Diambil'},
          ]
        : const [
            {'key': 'menyiapkan', 'label': 'Disiapkan'},
            {'key': 'menuju_lokasi', 'label': 'Di Jalan'},
            {'key': 'hampir_sampai', 'label': 'Hampir Tiba'},
            {'key': 'sudah_di_lokasi', 'label': 'Sampai'},
          ];
    final currentKey = order.resolvedStatusKurir;
    int activeIdx = steps.indexWhere((s) => s['key'] == currentKey);
    if (activeIdx < 0) activeIdx = 0;

    final String? etaWib = order.formattedEtaWib;
    final String etaText = etaWib != null
        ? 'Estimasi ±${order.resolvedEtaMinutes} mnt · sekitar $etaWib'
        : 'Estimasi ±${order.resolvedEtaMinutes} menit';

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.status.toLowerCase() == 'dikirim'
                      ? (isPickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded)
                      : Icons.schedule_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS KURIR & PERKIRAAN TIBA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: context.brandGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.resolvedStatusKurirLabel,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.tahuTagBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.tahuTagBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled_rounded, size: 16, color: context.brandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    etaText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.isDark ? AppTheme.emeraldBright : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length, (i) {
              final done = i <= activeIdx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: done ? context.brandGreen : context.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i]['label']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                          color: done ? context.brandGreen : context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTransfer = widget.order.paymentMethod.toLowerCase().contains('transfer');
    bool canCancel = widget.order.status == 'Pending' ||
        widget.order.status == 'Diproses' ||
        widget.order.status == 'Menunggu Pengiriman' ||
        widget.order.status == 'Menunggu Verifikasi';
    bool isSelesai = widget.order.status.toLowerCase() == 'selesai';
    bool isDikirim = widget.order.status.toLowerCase() == 'dikirim';

    Color statusColor = context.brandAmber;
    Color statusBg = context.limbahTagBg;
    Color statusBorder = context.limbahTagBorder;

    if (widget.order.status == 'Dibatalkan') {
      statusColor = context.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      statusBg = context.isDark ? AppTheme.dangerDarkSoft : Colors.red.shade50;
      statusBorder = context.isDark ? const Color(0xFFF87171).withValues(alpha: 0.4) : Colors.red.shade200;
    } else if (widget.order.status == 'Selesai') {
      statusColor = context.brandGreen;
      statusBg = context.tahuTagBg;
      statusBorder = context.tahuTagBorder;
    } else if (widget.order.status == 'Dikirim') {
      statusColor = context.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      statusBg = context.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF);
      statusBorder = context.isDark ? const Color(0xFF60A5FA).withValues(alpha: 0.4) : const Color(0xFF93C5FD);
    }

    String namaBank = "Bank";
    if (widget.order.bankTujuan != null && widget.order.bankTujuan!.isNotEmpty) {
      namaBank = widget.order.bankTujuan!;
    } else if (widget.order.paymentMethod.contains('(') && widget.order.paymentMethod.contains(')')) {
      namaBank = widget.order.paymentMethod.split('(')[1].replaceAll(')', '');
    }

    String nomorVA = "8888";
    if (widget.order.orderNumber.length >= 8) {
      nomorVA += widget.order.orderNumber.substring(widget.order.orderNumber.length - 8);
    } else {
      nomorVA += widget.order.orderNumber;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark ? AppTheme.darkSurface.withOpacity(0.85) : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
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
          'Detail Pesanan',
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
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 360,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: 0.08),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ================= 1. HEADER STATUS CARD =================
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Pesanan', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                widget.order.orderNumber,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Text(
                              widget.order.status.replaceAll('_', ' '),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Waktu Pesan: ${widget.order.formattedDate}',
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= 1B. STATUS KURIR & ESTIMASI TIBA =================
                if (widget.order.status.toLowerCase() == 'diproses' ||
                    widget.order.status.toLowerCase() == 'dikirim') ...[
                  _buildCourierEtaCard(context),
                  const SizedBox(height: 16),
                ],

                // ================= 2. LACAK KURIR SHORTCUT (IF DIKIRIM) =================
                if (isDikirim) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showTrackingDialog(context),
                      icon: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                      label: const Text('Lacak Posisi Kurir Secara Live', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================= 3. INFO PENGIRIMAN =================
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Color(0xFF059669), size: 18),
                          const SizedBox(width: 8),
                          Text('Informasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                        ],
                      ),
                      Divider(height: 20, color: context.border),
                      _buildDetailRow('Metode Pengiriman', widget.order.pickupMethod),
                      if (widget.order.customerName != null && widget.order.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Penerima', widget.order.customerName!),
                      ],
                      if (widget.order.phone != null && widget.order.phone!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Nomor HP', widget.order.phone!),
                      ],
                      if (widget.order.address != null && widget.order.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Alamat Tujuan', widget.order.address!),
                      ],
                      if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Catatan', widget.order.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= 4. ITEM PESANAN =================
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Color(0xFF059669), size: 18),
                          const SizedBox(width: 8),
                          Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                        ],
                      ),
                      Divider(height: 20, color: context.border),
                      if (widget.order.items.isNotEmpty) ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.order.items.length,
                          separatorBuilder: (context, index) => Divider(height: 20, color: context.border),
                          itemBuilder: (context, index) {
                            final item = widget.order.items[index];
                            final isLimbah = item.itemType == 'limbah';
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isLimbah 
                                        ? (context.isDark ? const Color(0xFF78350F).withOpacity(0.3) : const Color(0xFFFEF3C7))
                                        : (context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFF0FDF4)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLimbah ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isLimbah ? Icons.grain_rounded : Icons.eco_rounded,
                                    color: isLimbah ? const Color(0xFFD97706) : const Color(0xFF059669),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.qty} × ${formatCurrency(item.price)}',
                                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(item.subtotal),
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.textPrimary),
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${widget.order.productName} × ${widget.order.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            Text(formatCurrency(widget.order.subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= 5. VIRTUAL ACCOUNT CARD (FOR TRANSFER) =================
                if (isTransfer && widget.order.status != 'Dibatalkan' && widget.order.status != 'Selesai') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF047857), Color(0xFF065F46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047857).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
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
                                const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('$namaBank Virtual Account', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text(namaBank.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Nomor Virtual Account', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(nomorVA, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5)),
                            InkWell(
                              onTap: () => _copyToClipboard(nomorVA, 'Nomor VA'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text('Salin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.25), height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Transfer', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(formatCurrency(widget.order.totalPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                              ],
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(widget.order.totalPrice.toString(), 'Nominal'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy_rounded, color: Colors.white70, size: 11),
                                    SizedBox(width: 4),
                                    Text('Salin Nominal', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upload Bukti Glass Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 8),
                            Text('Upload Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Lampirkan foto struk pembayaran Anda.', style: TextStyle(fontSize: 11, color: context.textSecondary)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _isUploaded ? null : _pickImage,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.isDark ? AppTheme.darkSurface : Colors.white,
                              border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.4) : const Color(0xFF10B981).withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedImage == null ? 'Pilih File' : 'Ganti File',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedImage == null ? 'Belum ada file dipilih' : _selectedImage!.name,
                                    style: TextStyle(fontSize: 11, color: _selectedImage == null ? context.textMuted : context.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                ? (context.isDark ? Colors.grey.shade800 : Colors.grey.shade300) 
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: (_selectedImage == null || _isUploading || _isUploaded) ? null : _handleUpload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isUploading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isUploaded ? 'Bukti Terkirim' : 'Kirim Bukti Transfer',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================= 6. RINGKASAN PEMBAYARAN =================
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, color: Color(0xFF059669), size: 18),
                          const SizedBox(width: 8),
                          Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                        ],
                      ),
                      Divider(height: 20, color: context.border),
                      _buildDetailRow('Metode Pembayaran', widget.order.paymentMethod),
                      const SizedBox(height: 8),
                      _buildDetailRow('Subtotal Produk', formatCurrency(widget.order.subtotal)),
                      if (widget.order.discount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Diskon Order Pertama',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.brandGreen),
                            ),
                            Text(
                              '-${formatCurrency(widget.order.discount)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.brandGreen),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildDetailRow('Biaya Pengiriman (Ongkir)', formatCurrency(widget.order.shippingCost)),
                      Divider(height: 22, color: context.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                          Text(
                            formatCurrency(widget.order.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ================= 7. ACTION BUTTONS =================
                if (isSelesai) ...[
                  if (widget.order.items.length > 1) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Beri Ulasan Produk:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                      ),
                    ),
                    ...widget.order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _showReviewDialog(context, item),
                              icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              label: Text('Ulas: ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        )),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showReviewDialog(context, widget.order.items.isNotEmpty ? widget.order.items.first : null),
                        icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        label: const Text('Beri Ulasan & Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    if (canCancel) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFF87171)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: context.isDark ? const Color(0xFF7F1D1D).withOpacity(0.25) : Colors.red.shade50.withValues(alpha: 0.5),
                          ),
                          child: const Text('Batalkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
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
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
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

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimary),
          ),
        ),
      ],
    );
  }
}
