import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

/// Menyimpan data toko, kontak, tarif ongkir, dan daftar kecamatan yang
/// disinkronkan langsung dengan endpoint Laravel `/api/toko` (`config/toko.php`).
class StoreProvider extends ChangeNotifier {
  String _nama = 'Pabrik Tahu EcoTahu';
  String _alamat =
      'Lingkungan Panji, Tegalgede, Kec. Sumbersari, Kabupaten Jember, Jawa Timur 68124';
  String _whatsapp = '6283833722986';
  String _whatsappDisplay = '0838-3372-2986';
  String _email = 'hello@ecotahu.id';
  String _jamOperasional = 'Setiap Hari, 06.00 – 17.00 WIB';

  String _instagramLabel = '@jbr.iel';
  String _instagramUrl = 'https://www.instagram.com/jbr.iel';
  String _tiktokLabel = '@jbr.iel';
  String _tiktokUrl = 'https://www.tiktok.com/@jbr.iel';
  String _facebookLabel = 'Zeki Zaki';
  String _facebookUrl = 'https://www.facebook.com/share/19vBvyrxDe/';

  double _lat = -8.161482;
  double _lng = 113.724290;
  int _ongkirPerKm = 2500;
  int _ongkirMinimal = 5000;
  double _radiusMaksKm = 10.0;
  int _minimalDelivery = 15000;
  bool _promoAktif = true;
  int _promoPersen = 10;
  int _promoMaxDiskon = 5000;
  int _promoMinBelanja = 20000;

  Map<String, LatLng> _kecamatan = {
    'Ajung': const LatLng(-8.2167, 113.6500),
    'Ambulu': const LatLng(-8.3500, 113.6000),
    'Arjasa': const LatLng(-8.1200, 113.8300),
    'Balung': const LatLng(-8.2700, 113.5300),
    'Bangsalsari': const LatLng(-8.2200, 113.5200),
    'Gumukmas': const LatLng(-8.3200, 113.4100),
    'Jelbuk': const LatLng(-8.0500, 113.8000),
    'Jenggawah': const LatLng(-8.2700, 113.6500),
    'Jombang': const LatLng(-8.2100, 113.7000),
    'Kalisat': const LatLng(-8.1300, 113.8000),
    'Kaliwates': const LatLng(-8.1800, 113.6800),
    'Kencong': const LatLng(-8.2700, 113.3700),
    'Ledokombo': const LatLng(-8.1400, 113.8600),
    'Mayang': const LatLng(-8.1800, 113.7800),
    'Mumbulsari': const LatLng(-8.2400, 113.7300),
    'Pakusari': const LatLng(-8.1500, 113.7800),
    'Panti': const LatLng(-8.0800, 113.6300),
    'Patrang': const LatLng(-8.1350, 113.7150),
    'Puger': const LatLng(-8.2700, 113.4500),
    'Rambipuji': const LatLng(-8.2000, 113.6200),
    'Semboro': const LatLng(-8.2200, 113.4400),
    'Silo': const LatLng(-8.2500, 113.8500),
    'Sukorambi': const LatLng(-8.1400, 113.6800),
    'Sukowono': const LatLng(-8.1000, 113.8400),
    'Sumberbaru': const LatLng(-8.1300, 113.4000),
    'Sumberjambe': const LatLng(-8.0800, 113.7800),
    'Sumbersari': const LatLng(-8.1680, 113.7150),
    'Tanggul': const LatLng(-8.1600, 113.4600),
    'Tempurejo': const LatLng(-8.3200, 113.7300),
    'Umbulsari': const LatLng(-8.2500, 113.4500),
    'Wuluhan': const LatLng(-8.3400, 113.5300),
  };

  bool _loaded = false;
  bool _isLoading = false;

  String get nama => _nama;
  String get alamat => _alamat;
  String get whatsapp => _whatsapp;
  String get whatsappDisplay => _whatsappDisplay;
  String get email => _email;
  String get jamOperasional => _jamOperasional;

  String get instagramLabel => _instagramLabel;
  String get instagramUrl => _instagramUrl;
  String get tiktokLabel => _tiktokLabel;
  String get tiktokUrl => _tiktokUrl;
  String get facebookLabel => _facebookLabel;
  String get facebookUrl => _facebookUrl;

  double get lat => _lat;
  double get lng => _lng;
  LatLng get storeLocation => LatLng(_lat, _lng);
  int get ongkirPerKm => _ongkirPerKm;
  int get ongkirMinimal => _ongkirMinimal;
  double get radiusMaksKm => _radiusMaksKm;
  int get minimalDelivery => _minimalDelivery;
  bool get promoAktif => _promoAktif;
  int get promoPersen => _promoPersen;
  int get promoMaxDiskon => _promoMaxDiskon;
  int get promoMinBelanja => _promoMinBelanja;
  Map<String, LatLng> get kecamatan => Map.unmodifiable(_kecamatan);

  bool get isLoaded => _loaded;
  bool get isLoading => _isLoading;

  /// Mengonversi nomor format `628...` menjadi tampilan lokal `08xx-xxxx-xxxx`.
  static String formatWhatsAppDisplay(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.length >= 10) {
      return '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
    }
    return digits.isEmpty ? raw : digits;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Uri buildWhatsAppUri(String message) {
    final cleanWa = _whatsapp.replaceAll(RegExp(r'\D'), '');
    return Uri.parse(
      'https://wa.me/$cleanWa?text=${Uri.encodeComponent(message)}',
    );
  }

  Uri buildEmailUri({String? subject}) {
    return Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
  }

  Uri buildMapsUri() {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
  }

  /// Memuat ulang konfigurasi toko terbaru dari server Laravel `/api/toko`.
  Future<void> loadStoreInfo({bool force = false}) async {
    if (_isLoading) return;
    if (_loaded && !force) return;

    _isLoading = true;
    try {
      final data = await ApiService().getTokoInfo();
      if (data == null) return;

      final namaVal = data['nama']?.toString().trim();
      if (namaVal != null && namaVal.isNotEmpty) _nama = namaVal;

      final alamatVal = data['alamat']?.toString().trim();
      if (alamatVal != null && alamatVal.isNotEmpty) _alamat = alamatVal;

      final waVal = data['whatsapp']?.toString().replaceAll(RegExp(r'\D'), '');
      if (waVal != null && waVal.isNotEmpty) {
        _whatsapp = waVal;
        final waDisp = data['whatsapp_display']?.toString().trim();
        _whatsappDisplay = (waDisp != null && waDisp.isNotEmpty)
            ? waDisp
            : formatWhatsAppDisplay(waVal);
      } else {
        final waDisp = data['whatsapp_display']?.toString().trim();
        if (waDisp != null && waDisp.isNotEmpty) _whatsappDisplay = waDisp;
      }

      final emailVal = data['email']?.toString().trim();
      if (emailVal != null && emailVal.isNotEmpty) _email = emailVal;

      final jamVal = data['jam_operasional']?.toString().trim();
      if (jamVal != null && jamVal.isNotEmpty) _jamOperasional = jamVal;

      final rawSosmed = data['sosmed'];
      if (rawSosmed is Map) {
        final ig = rawSosmed['instagram'];
        if (ig is Map) {
          final l = ig['label']?.toString().trim();
          final u = ig['url']?.toString().trim();
          if (l != null && l.isNotEmpty) _instagramLabel = l;
          if (u != null && u.isNotEmpty) _instagramUrl = u;
        }
        final tt = rawSosmed['tiktok'];
        if (tt is Map) {
          final l = tt['label']?.toString().trim();
          final u = tt['url']?.toString().trim();
          if (l != null && l.isNotEmpty) _tiktokLabel = l;
          if (u != null && u.isNotEmpty) _tiktokUrl = u;
        }
        final fb = rawSosmed['facebook'];
        if (fb is Map) {
          final l = fb['label']?.toString().trim();
          final u = fb['url']?.toString().trim();
          if (l != null && l.isNotEmpty) _facebookLabel = l;
          if (u != null && u.isNotEmpty) _facebookUrl = u;
        }
      }

      _lat = _toDouble(data['lat']) ?? _lat;
      _lng = _toDouble(data['lng']) ?? _lng;
      _ongkirPerKm = _toInt(data['ongkir_per_km']) ?? _ongkirPerKm;
      _ongkirMinimal = _toInt(data['ongkir_minimal']) ?? _ongkirMinimal;
      _radiusMaksKm = _toDouble(data['radius_maks_km']) ?? _radiusMaksKm;
      _minimalDelivery = _toInt(data['minimal_delivery']) ?? _minimalDelivery;

      final rawPromo = data['promo_order_pertama'];
      if (rawPromo is Map) {
        if (rawPromo['aktif'] is bool) _promoAktif = rawPromo['aktif'] as bool;
        _promoPersen = _toInt(rawPromo['persen']) ?? _promoPersen;
        _promoMaxDiskon = _toInt(rawPromo['max_diskon']) ?? _promoMaxDiskon;
        _promoMinBelanja = _toInt(rawPromo['min_belanja']) ?? _promoMinBelanja;
      }

      final rawKec = data['kecamatan'];
      if (rawKec is Map) {
        final parsed = <String, LatLng>{};
        rawKec.forEach((key, value) {
          if (value is Map) {
            final kLat = _toDouble(value['lat']);
            final kLng = _toDouble(value['lng']);
            if (kLat != null && kLng != null) {
              parsed[key.toString()] = LatLng(kLat, kLng);
            }
          }
        });
        if (parsed.isNotEmpty) {
          _kecamatan = parsed;
        }
      }

      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Tetap gunakan nilai default yang tersinkron jika server offline
    } finally {
      _isLoading = false;
    }
  }
}
