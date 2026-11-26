import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/order_provider.dart';
import '../providers/store_provider.dart';
import '../services/api_service.dart';
import '../services/local_cache_service.dart';
import '../services/local_notification_service.dart';
import '../services/location_service.dart';
import '../widgets/auth_guard.dart';
import '../widgets/offline_banner.dart';
import 'transfer_payment_screen.dart';
import 'order_success_screen.dart';
import '../theme/app_theme.dart';
import '../services/secure_storage_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _shippingMethod = 'delivery'; 
  String _paymentMethod = 'COD'; 
  String? _selectedBank; 
  String? _selectedDistrict;
  
  LatLng? _pickedLocation;
  double _distance = 0.0;
  int _shippingCost = 0;
  String _locationSource = 'Kec. Sumbersari';
  final MapController _mapController = MapController();

  final List<String> _banks = ['BCA', 'BRI', 'Mandiri', 'BNI'];

  bool _isProcessing = false;
  bool _isMapReady = false;
  bool _isLocating = false;

  bool _promoEligible = false;
  bool _promoApplied = false;
  bool _promoBlockedByPhone = false;
  int _promoPersen = 10;
  int _promoMaxDiskon = 5000;
  int _promoDiscount = 0;
  int _promoKurangMinimal = 0;
  String? _promoReason;
  String _promoLabel = 'Diskon 10% Order Pertama';
  Timer? _phonePromoDebounce;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChangedForPromo);

    // Pre-fill cepat dari AuthProvider agar langsung terisi sejak frame pertama
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userName.isNotEmpty) _nameController.text = auth.userName;
    if (auth.userPhone.isNotEmpty) _phoneController.text = auth.userPhone;
    if (auth.userAddress.isNotEmpty) _addressController.text = auth.userAddress;

    _loadUserProfile();

    final store = Provider.of<StoreProvider>(context, listen: false);
    final districts = store.kecamatan;
    final initialDistrict = districts.containsKey('Sumbersari')
        ? 'Sumbersari'
        : (districts.isNotEmpty ? districts.keys.first : null);

    _selectedDistrict = initialDistrict;
    final initialLoc = (initialDistrict != null ? districts[initialDistrict] : null) ??
        store.storeLocation;
    _pickedLocation = initialLoc;
    _locationSource = initialDistrict != null ? 'Kec. $initialDistrict' : 'Titik Toko';
    _calculateDistance(initialLoc, source: _locationSource, moveCamera: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await store.loadStoreInfo(force: true);
      if (!mounted) return;
      final currentPin = _pickedLocation;
      if (currentPin != null) {
        _calculateDistance(currentPin, moveCamera: false);
      }
      _checkFirstOrderPromo();
    });
  }

  Future<void> _loadUserProfile() async {
    final token = await SecureStorageService.readToken();
    if (token != null) {
      final profile = await ApiService().getUserProfile(token);
      if (profile != null && mounted) {
        final fullName = (profile['name'] ?? profile['username'])?.toString().trim() ?? '';
        final phoneVal = profile['no_telepon']?.toString().trim() ?? '';
        final addrVal = profile['alamat']?.toString().trim() ?? '';
        setState(() {
          if (_nameController.text.trim().isEmpty && fullName.isNotEmpty) {
            _nameController.text = fullName;
          }
          if (_phoneController.text.trim().isEmpty && phoneVal.isNotEmpty) {
            _phoneController.text = phoneVal;
          }
          if (_addressController.text.trim().isEmpty && addrVal.isNotEmpty) {
            _addressController.text = addrVal;
          }
        });
        _checkFirstOrderPromo();
      }
    }
  }

  void _onPhoneChangedForPromo() {
    _phonePromoDebounce?.cancel();
    _phonePromoDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _checkFirstOrderPromo();
    });
  }

  Future<void> _checkFirstOrderPromo() async {
    final token = await SecureStorageService.readToken();
    if (token == null || !mounted) return;

    final subtotal = Provider.of<CartProvider>(context, listen: false).subtotal;
    final data = await ApiService().checkFirstOrderPromo(
      token: token,
      subtotal: subtotal,
      noTelepon: _phoneController.text.trim(),
    );
    if (data == null || !mounted) return;

    setState(() {
      _promoEligible = data['eligible'] == true;
      _promoApplied = data['applied'] == true;
      _promoBlockedByPhone = data['blocked_by_phone'] == true;
      _promoPersen = int.tryParse(data['persen']?.toString() ?? '') ?? _promoPersen;
      _promoMaxDiskon = int.tryParse(data['max_diskon']?.toString() ?? '') ?? _promoMaxDiskon;
      _promoDiscount = int.tryParse(data['diskon']?.toString() ?? '') ?? 0;
      _promoKurangMinimal = int.tryParse(data['kurang_minimal']?.toString() ?? '') ?? 0;
      _promoReason = data['reason']?.toString();
      _promoLabel = data['label']?.toString() ?? 'Diskon $_promoPersen% Order Pertama';
    });
  }

  @override
  void dispose() {
    _phonePromoDebounce?.cancel();
    _phoneController.removeListener(_onPhoneChangedForPromo);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    if (_isMapReady) {
      try {
        _mapController.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  void _safeMoveMap(LatLng target, double zoom) {
    if (_isMapReady) {
      try {
        _mapController.move(target, zoom);
      } catch (_) {}
    }
  }

  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  double _haversineKm(LatLng a, LatLng b) {
    const double r = 6371.0;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final double dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final double lat1 = a.latitude * math.pi / 180.0;
    final double lat2 = b.latitude * math.pi / 180.0;
    final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  String? _findNearestKecamatan(LatLng pos, Map<String, LatLng> districts) {
    String? nearest;
    double minDistance = double.infinity;
    for (final entry in districts.entries) {
      final double d = _haversineKm(pos, entry.value);
      if (d < minDistance) {
        minDistance = d;
        nearest = entry.key;
      }
    }
    return nearest;
  }

  void _calculateDistance(
    LatLng targetLocation, {
    String? source,
    bool moveCamera = false,
    double? targetZoom,
  }) {
    final store = Provider.of<StoreProvider>(context, listen: false);
    final double distanceInKm = _haversineKm(store.storeLocation, targetLocation);
    final nearest = _findNearestKecamatan(targetLocation, store.kecamatan);

    setState(() {
      _pickedLocation = targetLocation;
      _distance = double.parse(distanceInKm.toStringAsFixed(2));
      if (nearest != null) {
        _selectedDistrict = nearest;
      }
      if (source != null) {
        _locationSource = source;
      }

      if (_distance > 0) {
        // Rumus ongkir web: max(ceil(jarak) * ongkirPerKm, ongkirMinimal)
        final int calculatedOngkir = _distance.ceil() * store.ongkirPerKm;
        _shippingCost = calculatedOngkir < store.ongkirMinimal ? store.ongkirMinimal : calculatedOngkir;
      } else {
        _shippingCost = 0;
      }
    });

    if (moveCamera && _isMapReady) {
      double zoom = targetZoom ?? 15.0;
      if (targetZoom == null) {
        try {
          zoom = _mapController.camera.zoom;
        } catch (_) {}
      }
      _safeMoveMap(targetLocation, zoom);
    }
  }

  void _onDistrictChanged(String? district) {
    final store = Provider.of<StoreProvider>(context, listen: false);
    final districts = store.kecamatan;
    if (district != null && districts.containsKey(district)) {
      setState(() {
        _selectedDistrict = district;
      });
      final LatLng newLoc = districts[district]!;
      _safeMoveMap(newLoc, 14.0);
      _calculateDistance(newLoc, source: 'Kec. $district', moveCamera: false);
    }
  }

  void _resetPin() {
    final store = Provider.of<StoreProvider>(context, listen: false);
    final districts = store.kecamatan;
    final targetDistrict = (districts.containsKey(_selectedDistrict) ? _selectedDistrict : null) ??
        (districts.containsKey('Sumbersari')
            ? 'Sumbersari'
            : (districts.isNotEmpty ? districts.keys.first : null));
    final targetLoc =
        (targetDistrict != null ? districts[targetDistrict] : null) ?? store.storeLocation;
    final sourceLabel = targetDistrict != null ? 'Kec. $targetDistrict' : 'Titik Toko';

    if (targetDistrict != null) {
      setState(() {
        _selectedDistrict = targetDistrict;
      });
    }
    _calculateDistance(targetLoc, source: sourceLabel, moveCamera: false);
    _safeMoveMap(store.storeLocation, 13.5);
  }

  Future<void> _pakaiLokasiSaya() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;

      final userLatLng = result.location;
      if (userLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Gagal mendapatkan lokasi saat ini. Silakan ketuk manual pada peta.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final store = Provider.of<StoreProvider>(context, listen: false);
      _calculateDistance(userLatLng, source: 'GPS Lokasi Saya', moveCamera: false);
      _safeMoveMap(userLatLng, 16.0);

      final maxRadiusText = store.radiusMaksKm % 1 == 0
          ? store.radiusMaksKm.toStringAsFixed(0)
          : store.radiusMaksKm.toString();

      if (_distance <= store.radiusMaksKm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi Anda ditemukan! Jarak $_distance km dari pabrik.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi Anda terdeteksi ($_distance km), namun di luar radius pengiriman maks $maxRadiusText km.'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _handleBuatPesanan(int subtotal, int discountAmount) async {
    if (context.read<ConnectivityProvider>().isOffline) {
      showOfflineActionAlert(
        context,
        actionLabel: 'checkout pesanan (keranjang tetap aman di HP Anda)',
      );
      return;
    }
    final canProceed = await AuthGuard.requireAuth(
      context,
      actionMessage: 'membuat pesanan checkout',
    );
    if (!canProceed || !mounted) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Penerima wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No. Telepon wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_addressController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat Lengkap wajib diisi minimal 10 karakter!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_shippingMethod == 'delivery') {
      final store = Provider.of<StoreProvider>(context, listen: false);
      final maxRadiusText = store.radiusMaksKm % 1 == 0
          ? store.radiusMaksKm.toStringAsFixed(0)
          : store.radiusMaksKm.toString();
      if (_pickedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan tentukan titik lokasi pengiriman pada peta!'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_distance > store.radiusMaksKm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi pengiriman melebihi batas radius ($maxRadiusText km). Jarak Anda saat ini: $_distance km.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final finalShippingCost = _shippingMethod == 'delivery' ? _shippingCost : 0;
    final totalBayar = (subtotal - discountAmount).clamp(0, 1 << 30) + finalShippingCost;

    final token = await SecureStorageService.readToken();

    if (token == null) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi telah berakhir, silakan login ulang.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    List<Map<String, dynamic>> itemsPayload = cart.items.map((item) {
      return {
        'produk_id': item.product.id,
        'item_type': item.product.type,
        'qty': item.quantity,
        'jumlah': item.quantity,
        'harga': item.product.priceValue,
      };
    }).toList();

    String kodePesanan = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final result = await ApiService().createOrder(
      token: token,
      kodePesanan: kodePesanan,
      subtotal: subtotal.toInt(),
      ongkir: finalShippingCost.toInt(),
      totalHarga: totalBayar.toInt(),
      paymentMethod: _paymentMethod == 'COD' ? 'COD' : 'Transfer',
      bankTujuan: _paymentMethod == 'Transfer' ? _selectedBank : null,
      deliveryType: _shippingMethod == 'pickup' ? 'Ambil di Tempat' : 'Diantar ke Kecamatan $_selectedDistrict',
      alamat: _addressController.text.trim(),
      noTelepon: _phoneController.text.trim(),
      catatan: _notesController.text.trim(),
      items: itemsPayload,
      latPin: _shippingMethod == 'delivery' ? _pickedLocation?.latitude : null,
      lngPin: _shippingMethod == 'delivery' ? _pickedLocation?.longitude : null,
      kecamatan: _shippingMethod == 'delivery' ? _selectedDistrict : null,
    );

    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      LocalNotificationService.instance.pollNow();
      final Map<String, dynamic> serverData = result['data'] is Map
          ? Map<String, dynamic>.from(result['data'])
          : <String, dynamic>{};
      final int serverId = int.tryParse(serverData['id']?.toString() ?? '') ?? 0;
      final String serverKode = serverData['kode_pesanan']?.toString() ?? kodePesanan;
      final int serverSubtotal = double.tryParse(serverData['subtotal']?.toString() ?? '')?.round() ?? subtotal;
      final int serverDiskon = double.tryParse(serverData['diskon']?.toString() ?? '')?.round() ?? discountAmount;
      final int serverOngkir = double.tryParse(serverData['ongkir']?.toString() ?? '')?.round() ?? finalShippingCost;
      final int serverTotal = double.tryParse(serverData['total_harga']?.toString() ?? '')?.round() ?? totalBayar;

      List<OrderItem> orderItems = cart.items.map((ci) {
        return OrderItem(
          id: 0,
          itemId: ci.product.id,
          itemType: ci.product.type,
          name: ci.product.name,
          qty: ci.quantity,
          price: ci.product.priceValue,
          subtotal: ci.product.priceValue * ci.quantity,
          image: ci.product.imageUrl,
        );
      }).toList();

      final newOrder = Order(
        id: serverId,
        orderNumber: serverKode,
        productName: cart.items.map((i) => i.product.name).join(', '),
        quantity: cart.items.fold(0, (sum, item) => sum + item.quantity),
        subtotal: serverSubtotal,
        discount: serverDiskon,
        shippingCost: serverOngkir,
        totalPrice: serverTotal,
        paymentMethod: _paymentMethod == 'COD' ? 'COD' : 'Transfer',
        bankTujuan: _paymentMethod == 'Transfer' ? _selectedBank : null,
        pickupMethod: _shippingMethod == 'pickup' ? 'Ambil di Tempat' : 'Diantar ke Kecamatan $_selectedDistrict',
        orderDate: DateTime.now(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        items: orderItems,
      );
      orderProvider.addOrder(newOrder);

      // Simpan langsung ke cache lokal & sinkronkan riwayat pesanan dari server
      // agar langsung muncul saat buka "Pesanan Saya" walaupun user langsung offline & close app.
      await LocalCacheService.prependOrder(newOrder.toJson());
      ApiService().getOrders(token);

      cart.clearCart();
      if (!mounted) return;

      if (_paymentMethod == 'Transfer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TransferPaymentScreen(order: newOrder)),
        );
      } else {
        newOrder.status = 'Pending';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrderSuccessScreen(order: newOrder)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal membuat pesanan'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final districts = store.kecamatan;
    final maxRadiusText = store.radiusMaksKm % 1 == 0
        ? store.radiusMaksKm.toStringAsFixed(0)
        : store.radiusMaksKm.toString();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Konfirmasi Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(child: Text('Keranjang Anda kosong.', style: TextStyle(color: context.textPrimary)));
          }

          final subtotal = cart.subtotal;
          final isMinPurchaseError = _shippingMethod == 'delivery' && subtotal < store.minimalDelivery;
          final isMaxDistanceError = _shippingMethod == 'delivery' && _distance > store.radiusMaksKm;

          bool canCheckout = true;
          if (isMinPurchaseError || isMaxDistanceError) canCheckout = false;
          if (_shippingMethod == 'delivery' && _selectedDistrict == null) canCheckout = false;
          if (_paymentMethod == 'Transfer' && _selectedBank == null) canCheckout = false;

          final finalShipping = _shippingMethod == 'delivery' && _selectedDistrict != null ? _shippingCost : 0;
          final discountAmount = _promoApplied ? _promoDiscount : 0;
          final finalTotal = (subtotal - discountAmount).clamp(0, 1 << 30) + finalShipping;

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. DATA PENERIMA
                    _buildSectionTitle('1. Data Penerima', Icons.person_pin_rounded),
                    const SizedBox(height: 10),
                    _buildGlassCard(
                      children: [
                        _buildInputField(
                          controller: _nameController,
                          label: 'Nama Lengkap Penerima *',
                          hint: 'Contoh: Ahmad Fauzi',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _phoneController,
                          label: 'Nomor WhatsApp / HP *',
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _addressController,
                          label: 'Alamat Lengkap Pengiriman *',
                          hint: 'Jalan, No. Rumah, RT/RW, Patokan (min. 10 karakter)',
                          icon: Icons.home_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _notesController,
                          label: 'Catatan untuk Penjual / Kurir',
                          hint: 'Contoh: Titip di pos satpam atau pagar hitam',
                          icon: Icons.edit_note_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. METODE PENGIRIMAN
                    _buildSectionTitle('2. Metode Pengiriman', Icons.local_shipping_rounded),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectCard(
                            title: 'Ambil Sendiri',
                            subtitle: 'GRATIS ONGKIR',
                            icon: Icons.storefront_rounded,
                            isSelected: _shippingMethod == 'pickup',
                            badgeColor: const Color(0xFF059669),
                            onTap: () => setState(() => _shippingMethod = 'pickup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectCard(
                            title: 'Diantar Kurir',
                            subtitle: 'Min. ${formatCurrency(store.minimalDelivery)}',
                            icon: Icons.delivery_dining_rounded,
                            isSelected: _shippingMethod == 'delivery',
                            badgeColor: const Color(0xFF2563EB),
                            onTap: () => setState(() => _shippingMethod = 'delivery'),
                          ),
                        ),
                      ],
                    ),

                    if (isMinPurchaseError) ...[
                      const SizedBox(height: 12),
                      _buildAlertBox(
                        'Minimum belanja untuk kurir antar adalah ${formatCurrency(store.minimalDelivery)} (Kurang ${formatCurrency((store.minimalDelivery - subtotal).toInt())}). Silakan tambah produk atau pilih Ambil Sendiri.',
                        Colors.red,
                      ),
                    ],

                    // 3. PETA LOKASI PENGIRIMAN (JIKA DELIVERY)
                    if (_shippingMethod == 'delivery') ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('3. Titik Lokasi Peta & Ongkir', Icons.map_rounded),
                      const SizedBox(height: 10),

                      _buildGlassCard(
                        padding: const EdgeInsets.all(14),
                        children: [
                          // Dropdown Kecamatan
                          DropdownButtonFormField<String>(
                            value: districts.containsKey(_selectedDistrict) ? _selectedDistrict : null,
                            dropdownColor: context.surfaceElevated,
                            style: TextStyle(color: context.textPrimary, fontSize: 13.5),
                            decoration: InputDecoration(
                              labelText: 'Pilih Kecamatan Pengiriman *',
                              labelStyle: TextStyle(color: context.textSecondary),
                              prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF059669), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.border),
                              ),
                              filled: true,
                              fillColor: context.isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                            ),
                            items: districts.keys
                                .map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(color: context.textPrimary, fontSize: 13.5))))
                                .toList(),
                            onChanged: _onDistrictChanged,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tekan "Pakai Lokasi Saya" atau ketuk titik lokasi Anda pada peta agar ongkir lebih presisi.',
                            style: TextStyle(fontSize: 11.5, color: context.textSecondary, height: 1.35),
                          ),
                          const SizedBox(height: 10),

                          // Leaflet Interactive Map
                          Container(
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _pickedLocation ?? store.storeLocation,
                                  initialZoom: 14.0,
                                  onMapReady: () {
                                    if (mounted) {
                                      setState(() {
                                        _isMapReady = true;
                                      });
                                    }
                                  },
                                  onTap: (tapPosition, point) {
                                    _calculateDistance(point, source: 'Pin Peta', moveCamera: true);
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.ecotahumobile',
                                  ),
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: store.storeLocation,
                                        radius: store.radiusMaksKm * 1000,
                                        useRadiusInMeter: true,
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderColor: const Color(0xFF059669),
                                        borderStrokeWidth: 2,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: store.storeLocation,
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                          ),
                                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                                        ),
                                      ),
                                      if (_pickedLocation != null)
                                        Marker(
                                          point: _pickedLocation!,
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.topCenter,
                                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLocating ? null : _pakaiLokasiSaya,
                                  icon: _isLocating
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.brandGreen,
                                          ),
                                        )
                                      : Icon(Icons.my_location_rounded, size: 15, color: context.brandGreen),
                                  label: Text(
                                    _isLocating ? 'Mencari...' : 'Pakai Lokasi Saya',
                                    style: TextStyle(
                                      color: context.brandGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: context.brandGreen.withValues(alpha: context.isDark ? 0.14 : 0.1),
                                    side: BorderSide(color: context.brandGreen.withValues(alpha: 0.45)),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _resetPin,
                                  icon: Icon(Icons.refresh_rounded, size: 15, color: context.textSecondary),
                                  label: Text(
                                    'Reset Pin',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Sumber, Jarak & Ongkir Strip (Sama seperti Web Checkout)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sumber', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _locationSource,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Jarak', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text('$_distance km', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.isDark
                                          ? AppTheme.emeraldLight.withValues(alpha: 0.3)
                                          : const Color(0xFF86EFAC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ongkir',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: context.brandGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatCurrency(_shippingCost),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.brandGreen),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (isMaxDistanceError) ...[
                            const SizedBox(height: 12),
                            _buildAlertBox(
                              'Lokasi di luar jangkauan (Maksimal $maxRadiusText km, saat ini: $_distance km). Silakan pilih opsi Ambil Sendiri.',
                              Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ],

                    // 4. METODE PEMBAYARAN
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      _shippingMethod == 'delivery' ? '4. Metode Pembayaran' : '3. Metode Pembayaran',
                      Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectCard(
                            title: 'COD (Bayar Tunai)',
                            subtitle: 'Bayar saat barang tiba',
                            icon: Icons.payments_outlined,
                            isSelected: _paymentMethod == 'COD',
                            badgeColor: const Color(0xFF059669),
                            onTap: () => setState(() => _paymentMethod = 'COD'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectCard(
                            title: 'Transfer Bank',
                            subtitle: 'Upload bukti transfer',
                            icon: Icons.account_balance_outlined,
                            isSelected: _paymentMethod == 'Transfer',
                            badgeColor: const Color(0xFF2563EB),
                            onTap: () => setState(() => _paymentMethod = 'Transfer'),
                          ),
                        ),
                      ],
                    ),

                    if (_paymentMethod == 'Transfer') ...[
                      const SizedBox(height: 14),
                      _buildGlassCard(
                        padding: const EdgeInsets.all(14),
                        children: [
                          Text(
                            'Pilih Bank Tujuan Pembayaran *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _banks.map((bank) {
                              final isSelected = _selectedBank == bank;
                              return ChoiceChip(
                                label: Text(
                                  bank,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected 
                                        ? (context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669)) 
                                        : context.textSecondary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFECFDF5),
                                backgroundColor: context.cardBg,
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF059669) : context.border,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (sel) => setState(() => _selectedBank = sel ? bank : null),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],

                    // 5. RINGKASAN PEMESANAN
                    const SizedBox(height: 24),
                    _buildSectionTitle('Ringkasan Akhir', Icons.receipt_long_rounded),
                    const SizedBox(height: 10),
                    _buildGlassCard(
                      children: [
                        // Daftar Produk yang di-checkout (Sama seperti di Web)
                        ...cart.items.map((cartItem) {
                          final isLimbah = cartItem.product.type == 'limbah';
                          final itemSubtotal = cartItem.product.priceValue * cartItem.quantity;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isLimbah 
                                        ? (context.isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                                        : (context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFECFDF5)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isLimbah
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: cartItem.product.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(9),
                                          child: Image.network(
                                            cartItem.product.imageUrl,
                                            width: 42,
                                            height: 42,
                                            cacheWidth: 400,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Icon(
                                                isLimbah ? Icons.recycling_rounded : Icons.eco_rounded,
                                                size: 20,
                                                color: isLimbah ? context.brandAmber : context.brandGreen,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          isLimbah ? Icons.recycling_rounded : Icons.eco_rounded,
                                          size: 20,
                                          color: isLimbah ? context.brandAmber : context.brandGreen,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.product.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${cartItem.quantity} × ${formatCurrency(cartItem.product.priceValue)}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(itemSubtotal),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Divider(color: context.border),
                        ),
                        if (_promoApplied && discountAmount > 0) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: context.tahuTagBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.tahuTagBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.card_giftcard_rounded, size: 17, color: context.brandGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$_promoLabel aktif! Hemat ${formatCurrency(discountAmount)} untuk order pertamamu.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.brandGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_promoEligible && _promoKurangMinimal > 0) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.28)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 17,
                                  color: context.isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tambah belanja ${formatCurrency(_promoKurangMinimal)} lagi untuk dapat $_promoLabel (maks. ${formatCurrency(_promoMaxDiskon)}).',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_promoBlockedByPhone && (_promoReason ?? '').isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: context.limbahTagBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.limbahTagBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 17, color: context.brandAmber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _promoReason!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.limbahTagText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _buildSummaryRow('Subtotal Belanja', formatCurrency(subtotal)),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: 10),
                          _buildSummaryRow(
                            'Diskon Order Pertama ($_promoPersen%)',
                            '-${formatCurrency(discountAmount)}',
                            valueColor: context.brandGreen,
                            labelColor: context.brandGreen,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                          _shippingMethod == 'delivery' && _selectedDistrict != null
                              ? 'Ongkir ($_distance km)'
                              : 'Ongkir Toko',
                          _shippingMethod == 'delivery' && _selectedDistrict != null
                              ? formatCurrency(_shippingCost)
                              : 'Rp 0 (Gratis)',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: context.border),
                        ),
                        _buildSummaryRow('Total Pembayaran', formatCurrency(finalTotal), isTotal: true),
                      ],
                    ),
                  ],
                ),
              ),

              // STICKY BOTTOM CONFIRM BAR
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        color: context.surface.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(
                          top: BorderSide(color: context.border, width: 1.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Tagihan',
                                  style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  formatCurrency(finalTotal),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.brandGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (canCheckout && !_isProcessing)
                                ? () => _handleBuatPesanan(subtotal, discountAmount)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.brandGreenSolid,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: context.isDark ? Colors.grey.shade800 : const Color(0xFFCBD5E1),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                              elevation: 3,
                              shadowColor: context.brandGreenSolid.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    children: [
                                      Text('Konfirmasi & Pesan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                      SizedBox(width: 6),
                                      Icon(Icons.check_circle_rounded, size: 16),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.brandGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required List<Widget> children, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.5, color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: context.textSecondary, size: 20),
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
        filled: true,
        fillColor: context.isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildSelectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.tahuTagBg
              : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.brandGreenSolid : context.border,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.brandGreen.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? context.brandGreen : context.textSecondary, size: 22),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: context.brandGreen, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: isSelected 
                    ? (context.isDark ? AppTheme.emeraldLight : const Color(0xFF065F46)) 
                    : context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected 
                    ? (context.isDark ? AppTheme.emeraldLight.withValues(alpha: 0.8) : const Color(0xFF047857)) 
                    : context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            fontSize: isTotal ? 15 : 13,
            color: labelColor ?? (isTotal ? context.textPrimary : context.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? (isTotal ? context.brandGreen : context.textPrimary),
            fontSize: isTotal ? 17 : 13.5,
          ),
        ),
      ],
    );
  }
}
