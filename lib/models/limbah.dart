import 'package:intl/intl.dart';
import 'product.dart';

class Limbah {
  final int id;
  final String name;
  final int priceValue;
  final String price;
  final int stok;
  final String satuan;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewsCount;

  Limbah({
    required this.id,
    required this.name,
    required this.priceValue,
    required this.price,
    required this.stok,
    required this.satuan,
    required this.imageUrl,
    required this.description,
    this.rating = 0.0,
    this.reviewsCount = 0,
  });

  factory Limbah.fromJson(Map<String, dynamic> json) {
    double hargaParsed = double.tryParse(json['harga'].toString()) ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    String gambarUrl = ''; 
    
    if (json['gambar_url'] != null && json['gambar_url'].toString().trim().isNotEmpty) {
      gambarUrl = json['gambar_url'].toString().trim();
    } else if (json['gambar'] != null && json['gambar'].toString().trim().isNotEmpty) {
      String pathGambar = json['gambar'].toString().trim();
      
      if (pathGambar.startsWith('http://') || pathGambar.startsWith('https://')) {
        gambarUrl = pathGambar;
      } else {
        String cleanPath = pathGambar.replaceFirst('storage/', '');
        if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
        gambarUrl = 'http://localhost:8000/files/$cleanPath';
      }
    }

    if (gambarUrl.isNotEmpty && gambarUrl.contains('127.0.0.1:8000')) {
      gambarUrl = gambarUrl.replaceFirst('127.0.0.1:8000', 'localhost:8000');
    }

    double parsedRating = double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0;
    int parsedReviews = int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0;

    return Limbah(
      id: json['id'],
      name: json['nama_limbah'] ?? json['nama_produk'] ?? 'Produk Limbah',
      priceValue: hargaParsed.toInt(),
      price: '${formatter.format(hargaParsed)} / ${json['satuan'] ?? 'kg'}',
      stok: json['stok'] ?? 0,
      satuan: json['satuan'] ?? 'kg',
      imageUrl: gambarUrl,
      description: json['deskripsi'] ?? '',
      rating: parsedRating,
      reviewsCount: parsedReviews,
    );
  }

  Product toProduct() {
    return Product(
      id: id,
      kategoriId: 2,
      name: name,
      slug: '',
      description: description,
      priceValue: priceValue,
      price: price,
      stok: stok,
      satuan: satuan,
      imageUrl: imageUrl,
      rating: rating,
      reviewsCount: reviewsCount,
      type: 'limbah',
    );
  }
}
