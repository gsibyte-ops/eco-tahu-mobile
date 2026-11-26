import 'package:intl/intl.dart';

class OrderItem {
  final int id;
  final int itemId;
  final String itemType; // 'tahu' atau 'limbah'
  final String name;
  final int qty;
  final int price;
  final int subtotal;
  final String? image;

  OrderItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.qty,
    required this.price,
    required this.subtotal,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic val) {
      if (val == null) return 0;
      return double.tryParse(val.toString())?.toInt() ?? 0;
    }

    String rawType = (json['item_type'] ?? json['itemType'] ?? '').toString().toLowerCase();
    String cleanType = rawType.contains('limbah') ? 'limbah' : 'tahu';
    final int unitPrice = parseToInt(json['harga_satuan'] ?? json['harga'] ?? json['price']);
    final int itemQty = parseToInt(json['jumlah'] ?? json['qty'] ?? 1);

    return OrderItem(
      id: parseToInt(json['id']),
      itemId: parseToInt(json['item_id'] ?? json['itemId'] ?? json['produk_id']),
      itemType: cleanType,
      name: (json['nama_item'] ?? json['nama'] ?? json['name'] ?? 'Produk').toString(),
      qty: itemQty > 0 ? itemQty : 1,
      price: unitPrice,
      subtotal: parseToInt(json['subtotal'] ?? (unitPrice * (itemQty > 0 ? itemQty : 1))),
      image: json['gambar'] ?? json['image'] ?? (json['item'] != null ? json['item']['gambar'] : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemType': itemType,
        'name': name,
        'qty': qty,
        'price': price,
        'subtotal': subtotal,
        'image': image,
      };
}

class Order {
  final int id;
  final String orderNumber;
  final String productName; 
  final int quantity;
  final int subtotal;
  final int discount;
  final int shippingCost;
  final int totalPrice;
  final String paymentMethod;
  final String? bankTujuan;
  final String pickupMethod;
  final DateTime orderDate;
  String status;
  int? estimasiMenit;
  DateTime? estimasiTiba;
  String? statusKurir;
  String? statusKurirLabel;
  String? cancelReason;
  String? address;
  String? notes;
  String? customerName;
  String? phone;
  double? latitude;
  double? longitude;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.productName,
    required this.quantity,
    required this.subtotal,
    this.discount = 0,
    required this.shippingCost,
    required this.totalPrice,
    required this.paymentMethod,
    this.bankTujuan,
    required this.pickupMethod,
    required this.orderDate,
    this.status = 'Pending',
    this.estimasiMenit,
    this.estimasiTiba,
    this.statusKurir,
    this.statusKurirLabel,
    this.cancelReason,
    this.address,
    this.notes,
    this.customerName,
    this.phone,
    this.latitude,
    this.longitude,
    this.items = const [],
  });

  static const Map<String, String> courierStatusLabels = {
    'menyiapkan': 'Admin sedang menyiapkan pesanan',
    'menuju_lokasi': 'Kurir sedang dalam perjalanan menuju lokasimu',
    'hampir_sampai': 'Kurir sudah dekat di sekitar lokasimu (±5 menit lagi)',
    'sudah_di_lokasi': 'Kurir sudah tiba di lokasi tujuan',
    'siap_diambil': 'Pesanan sudah siap diambil di lokasi EcoTahu',
  };

  bool get isPickupOrder => pickupMethod.toLowerCase().contains('ambil');

  int get resolvedEtaMinutes {
    if (estimasiMenit != null && estimasiMenit! > 0) return estimasiMenit!;
    return isPickupOrder ? 15 : 25;
  }

  String? get formattedEtaWib {
    if (estimasiTiba == null) return null;
    final wib = estimasiTiba!.toUtc().add(const Duration(hours: 7));
    final hh = wib.hour.toString().padLeft(2, '0');
    final mm = wib.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }

  String get resolvedStatusKurir {
    if (statusKurir != null && statusKurir!.isNotEmpty) return statusKurir!;
    if (status.toLowerCase() == 'dikirim') {
      return isPickupOrder ? 'siap_diambil' : 'menuju_lokasi';
    }
    return 'menyiapkan';
  }

  String get resolvedStatusKurirLabel {
    if (statusKurirLabel != null && statusKurirLabel!.trim().isNotEmpty) {
      return statusKurirLabel!.trim();
    }
    if (statusKurir != null && courierStatusLabels.containsKey(statusKurir)) {
      return courierStatusLabels[statusKurir!]!;
    }
    return courierStatusLabels[resolvedStatusKurir] ?? 'Admin sedang menyiapkan pesanan';
  }

  String get formattedDate => DateFormat('dd MMM yyyy, HH:mm').format(orderDate);
  
  String get paymentDeadline {
    final deadline = orderDate.add(const Duration(hours: 24));
    return DateFormat('dd MMM yyyy, HH:mm').format(deadline);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'productName': productName,
        'quantity': quantity,
        'subtotal': subtotal,
        'discount': discount,
        'shippingCost': shippingCost,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'bankTujuan': bankTujuan,
        'pickupMethod': pickupMethod,
        'orderDate': orderDate.toIso8601String(),
        'status': status,
        'estimasiMenit': estimasiMenit,
        'estimasiTiba': estimasiTiba?.toIso8601String(),
        'statusKurir': statusKurir,
        'statusKurirLabel': statusKurirLabel,
        'cancelReason': cancelReason,
        'address': address,
        'notes': notes,
        'customerName': customerName,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic val) {
      if (val == null) return 0;
      return double.tryParse(val.toString())?.toInt() ?? 0;
    }

    double? parseToDouble(dynamic val) {
      if (val == null) return null;
      return double.tryParse(val.toString());
    }

    // Jika data dari Local Storage (toJson)
    if (json.containsKey('orderNumber')) {
      List<OrderItem> parsedItems = [];
      if (json['items'] != null && json['items'] is List) {
        parsedItems = (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList();
      }

      return Order(
        id: json['id'] ?? 0,
        orderNumber: json['orderNumber'],
        productName: json['productName'],
        quantity: json['quantity'],
        subtotal: json['subtotal'] ?? 0,
        discount: json['discount'] ?? json['diskon'] ?? 0,
        shippingCost: json['shippingCost'] ?? 0,
        totalPrice: json['totalPrice'] ?? 0,
        paymentMethod: json['paymentMethod'],
        bankTujuan: json['bankTujuan'],
        pickupMethod: json['pickupMethod'],
        orderDate: DateTime.parse(json['orderDate']),
        status: json['status'] ?? 'Pending',
        estimasiMenit: parseToInt(json['estimasiMenit']) > 0 ? parseToInt(json['estimasiMenit']) : null,
        estimasiTiba: json['estimasiTiba'] != null ? DateTime.tryParse(json['estimasiTiba'].toString()) : null,
        statusKurir: json['statusKurir']?.toString(),
        statusKurirLabel: json['statusKurirLabel']?.toString(),
        cancelReason: json['cancelReason'],
        address: json['address'],
        notes: json['notes'],
        customerName: json['customerName'],
        phone: json['phone'],
        latitude: parseToDouble(json['latitude']),
        longitude: parseToDouble(json['longitude']),
        items: parsedItems,
      );
    }

    // Jika data dari API Laravel
    List<OrderItem> parsedItems = [];
    String prodName = 'Produk';
    int totalQty = 0;

    if (json['detail'] != null && (json['detail'] as List).isNotEmpty) {
      parsedItems = (json['detail'] as List).map((d) => OrderItem.fromJson(d)).toList();
      prodName = parsedItems.map((i) => i.name).join(', ');
      totalQty = parsedItems.fold(0, (sum, i) => sum + i.qty);
    }

    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['kode_pesanan'] ?? json['kode'] ?? '-',
      productName: prodName,
      quantity: totalQty > 0 ? totalQty : 1,
      subtotal: parseToInt(json['subtotal']),
      discount: parseToInt(json['diskon'] ?? json['discount']),
      shippingCost: parseToInt(json['ongkir']),
      totalPrice: parseToInt(json['total_harga']),
      paymentMethod: json['payment_method'] ?? 'COD',
      bankTujuan: json['bank_tujuan'],
      pickupMethod: json['delivery_type'] == 'pickup' ? 'Ambil di Tempat' : 'Diantar',
      orderDate: json['tanggal_order'] != null 
          ? DateTime.parse(json['tanggal_order']) 
          : DateTime.now(),
      status: json['order_status'] ?? json['status'] ?? 'Pending',
      estimasiMenit: parseToInt(json['estimasi_menit']) > 0 ? parseToInt(json['estimasi_menit']) : null,
      estimasiTiba: json['estimasi_tiba'] != null ? DateTime.tryParse(json['estimasi_tiba'].toString()) : null,
      statusKurir: json['status_kurir']?.toString(),
      statusKurirLabel: json['status_kurir_label']?.toString(),
      address: json['alamat_pengiriman'] ?? json['alamat'],
      notes: json['catatan'],
      customerName: json['nama_penerima'] ?? json['nama'] ?? json['user']?['username'],
      phone: json['telepon_penerima'] ?? json['telepon'] ?? json['no_hp'] ?? json['user']?['phone'],
      latitude: parseToDouble(json['latitude'] ?? json['lat']),
      longitude: parseToDouble(json['longitude'] ?? json['lng']),
      items: parsedItems,
    );
  }
}
