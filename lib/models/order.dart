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

    String rawType = (json['item_type'] ?? '').toString().toLowerCase();
    String cleanType = rawType.contains('limbah') ? 'limbah' : 'tahu';

    return OrderItem(
      id: json['id'] ?? 0,
      itemId: json['item_id'] ?? json['produk_id'] ?? 0,
      itemType: cleanType,
      name: json['nama_item'] ?? json['nama'] ?? 'Produk',
      qty: parseToInt(json['jumlah'] ?? json['qty'] ?? 1),
      price: parseToInt(json['harga_satuan'] ?? json['harga']),
      subtotal: parseToInt(json['subtotal'] ?? (parseToInt(json['harga_satuan'] ?? json['harga']) * parseToInt(json['jumlah'] ?? 1))),
      image: json['gambar'] ?? (json['item'] != null ? json['item']['gambar'] : null),
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
    this.cancelReason,
    this.address,
    this.notes,
    this.customerName,
    this.phone,
    this.latitude,
    this.longitude,
    this.items = const [],
  });

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
