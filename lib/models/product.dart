import 'package:intl/intl.dart';
import '../config/app_config.dart';

class Product {
  final int id;
  final int kategoriId;
  final String name;
  final String slug;
  final String description;
  final int priceValue;
  final String price;
  final int stok;
  final String satuan;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String type; // 'tahu' atau 'limbah'

  Product({
    required this.id,
    required this.kategoriId,
    required this.name,
    required this.slug,
    required this.description,
    required this.priceValue,
    required this.price,
    required this.stok,
    required this.satuan,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.type = 'tahu',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kategori_id': kategoriId,
      'name': name,
      'slug': slug,
      'description': description,
      'price_value': priceValue,
      'price': price,
      'stok': stok,
      'satuan': satuan,
      'image_url': imageUrl,
      'rating': rating,
      'reviews_count': reviewsCount,
      'type': type,
    };
  }

  factory Product.fromCacheJson(Map<String, dynamic> json) {
    final int parsedPriceValue = int.tryParse(json['price_value']?.toString() ?? '0') ?? 0;
    final String parsedUnit = json['satuan']?.toString() ?? 'pcs';
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Product(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kategoriId: int.tryParse(json['kategori_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Produk',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceValue: parsedPriceValue,
      price: json['price']?.toString() ?? '${formatter.format(parsedPriceValue)} / $parsedUnit',
      stok: int.tryParse(json['stok']?.toString() ?? '0') ?? 0,
      satuan: parsedUnit,
      imageUrl: AppConfig.fileUrl(json['image_url']?.toString()),
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() == 'limbah' ? 'limbah' : 'tahu',
    );
  }

  factory Product.fromCartApiJson(Map<String, dynamic> json) {
    final double hargaParsed = double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final rawType = (json['mobile_type'] ?? json['type'])?.toString().toLowerCase() ?? 'tahu';
    final itemType = rawType == 'limbah' ? 'limbah' : 'tahu';
    final unit = json['satuan']?.toString() ?? (itemType == 'limbah' ? 'kg' : 'pcs');
    final rawImg = (json['gambar_url']?.toString().trim().isNotEmpty == true)
        ? json['gambar_url'].toString()
        : json['gambar']?.toString();

    return Product(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kategoriId: int.tryParse(json['kategori_id']?.toString() ?? '0') ?? 0,
      name: json['nama']?.toString() ?? json['nama_produk']?.toString() ?? 'Produk',
      slug: json['slug']?.toString() ?? '',
      description: json['deskripsi']?.toString() ?? '',
      priceValue: hargaParsed.toInt(),
      price: '${formatter.format(hargaParsed)} / $unit',
      stok: int.tryParse((json['stok_max'] ?? json['stok'])?.toString() ?? '0') ?? 0,
      satuan: unit,
      imageUrl: AppConfig.fileUrl(rawImg),
      type: itemType,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    double hargaParsed = double.tryParse(json['harga'].toString()) ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    String gambarUrl = '';

    if (json['gambar_url'] != null && json['gambar_url'].toString().trim().isNotEmpty) {
      gambarUrl = AppConfig.fileUrl(json['gambar_url'].toString());
    } else if (json['gambar'] != null && json['gambar'].toString().trim().isNotEmpty) {
      gambarUrl = AppConfig.fileUrl(json['gambar'].toString());
    }

    double parsedRating = double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0;
    int parsedReviews = int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0;

    return Product(
      id: json['id'],
      kategoriId: json['kategori_id'] ?? 0,
      name: json['nama_produk'] ?? json['nama_limbah'] ?? 'Produk',
      slug: json['slug'] ?? '',
      description: json['deskripsi'] ?? '',
      priceValue: hargaParsed.toInt(),
      price: '${formatter.format(hargaParsed)} / ${json['satuan'] ?? 'kg'}',
      stok: json['stok'] ?? 0,
      satuan: json['satuan'] ?? 'kg',
      imageUrl: gambarUrl,
      rating: parsedRating,
      reviewsCount: parsedReviews,
      type: 'tahu',
    );
  }
}
