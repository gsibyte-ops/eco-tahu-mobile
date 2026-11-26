import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final prodMap = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : <String, dynamic>{};
    return CartItem(
      product: Product.fromCacheJson(prodMap),
      quantity: (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1).clamp(1, 9999),
    );
  }
}

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'eco_tahu_cart_items_v1';
  static const String _pendingSyncKey = 'eco_tahu_cart_pending_sync_v1';

  final List<CartItem> _items = [];
  bool _isAdminMode = false;
  bool _isSyncing = false;
  bool _hasPendingSync = false;

  /// Mode Admin selalu melihat keranjang kosong (Read-Only) tanpa menghapus
  /// data keranjang milik akun pelanggan yang tersimpan lokal.
  List<CartItem> get items => _isAdminMode ? const [] : _items;
  bool get hasPendingSync => !_isAdminMode && _hasPendingSync;
  bool get isSyncing => _isSyncing;

  int get subtotal {
    if (_isAdminMode) return 0;
    int total = 0;
    for (final item in _items) {
      total += item.product.priceValue * item.quantity;
    }
    return total;
  }

  void setAdminMode(bool isAdmin) {
    if (_isAdminMode == isAdmin) return;
    _isAdminMode = isAdmin;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _setPendingSync(bool value) async {
    if (_hasPendingSync == value) return;
    _hasPendingSync = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, value);
    notifyListeners();
  }

  /// Muat keranjang tersimpan saat startup, lalu sinkronkan dengan server jika login.
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdminMode = prefs.getBool('is_admin') ?? false;
    _hasPendingSync = prefs.getBool(_pendingSyncKey) ?? false;

    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.clear();
          for (final entry in decoded) {
            if (entry is Map) {
              final item = CartItem.fromJson(Map<String, dynamic>.from(entry));
              if (item.product.id > 0) {
                _items.add(item);
              }
            }
          }
        }
      } catch (_) {}
    }

    notifyListeners();

    final token = await SecureStorageService.readToken();
    if (token != null && token.trim().isNotEmpty && !_isAdminMode) {
      await syncWithServer();
    }
  }

  /// Sinkronisasi dua arah antara keranjang lokal dan tabel `cart_items` di Laravel.
  /// Jika terdapat perubahan lokal yang dibuat saat offline (`_hasPendingSync`),
  /// perubahan lokal didorong ke server terlebih dahulu agar item tidak hilang/tertimpa.
  Future<void> syncWithServer() async {
    if (_isSyncing) return;
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('is_admin') ?? _isAdminMode;
    _isAdminMode = isAdmin;

    final token = await SecureStorageService.readToken();
    if (isAdmin || token == null || token.trim().isEmpty) {
      notifyListeners();
      return;
    }

    _isSyncing = true;
    notifyListeners();
    try {
      // 1. Bila ada perubahan offline yang belum terkirim ke server, flush state lokal sebagai sumber kebenaran
      if (_hasPendingSync) {
        final cleared = await ApiService().clearCartApi(token);
        if (!cleared) return;

        bool allPushed = true;
        for (final localItem in List<CartItem>.from(_items)) {
          final ok = await ApiService().addCartItem(
            token,
            itemType: localItem.product.type,
            itemId: localItem.product.id,
            qty: localItem.quantity,
          );
          if (!ok) {
            allPushed = false;
            break;
          }
        }

        if (allPushed) {
          await _setPendingSync(false);
        }
        return;
      }

      // 2. Normal two-way sync saat tidak ada antrean perubahan offline
      final serverItems = await ApiService().getCart(token);
      if (serverItems == null) return;

      if (serverItems.isEmpty && _items.isNotEmpty) {
        bool allOk = true;
        for (final localItem in List<CartItem>.from(_items)) {
          final ok = await ApiService().addCartItem(
            token,
            itemType: localItem.product.type,
            itemId: localItem.product.id,
            qty: localItem.quantity,
          );
          if (!ok) allOk = false;
        }
        if (!allOk) await _setPendingSync(true);
      } else if (serverItems.isNotEmpty) {
        final localSnapshot = List<CartItem>.from(_items);
        final merged = <CartItem>[];

        for (final sMap in serverItems) {
          final product = Product.fromCartApiJson(sMap);
          if (product.id <= 0) continue;
          final qty = (int.tryParse(sMap['qty']?.toString() ?? '1') ?? 1).clamp(1, 9999);
          merged.add(CartItem(product: product, quantity: qty));
        }

        // Jika ada item lokal yang belum masuk di server, dorong ke server juga
        for (final localItem in localSnapshot) {
          final existsOnServer = merged.any(
            (m) => m.product.id == localItem.product.id && m.product.type == localItem.product.type,
          );
          if (!existsOnServer) {
            final ok = await ApiService().addCartItem(
              token,
              itemType: localItem.product.type,
              itemId: localItem.product.id,
              qty: localItem.quantity,
            );
            if (ok) {
              merged.add(localItem);
            }
          }
        }

        _items
          ..clear()
          ..addAll(merged);
        await _saveToPrefs();
      }

      notifyListeners();
    } catch (_) {
      // Tetap pertahankan state keranjang lokal jika jaringan offline
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushAddToServer(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.readToken();
    final isAdmin = prefs.getBool('is_admin') ?? _isAdminMode;
    if (isAdmin || token == null || token.trim().isEmpty) return;

    final ok = await ApiService().addCartItem(
      token,
      itemType: product.type,
      itemId: product.id,
      qty: 1,
    );
    if (!ok) {
      await _setPendingSync(true);
    }
  }

  Future<void> _pushQtyToServer(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.readToken();
    final isAdmin = prefs.getBool('is_admin') ?? _isAdminMode;
    if (isAdmin || token == null || token.trim().isEmpty) return;

    final ok = await ApiService().updateCartItem(
      token,
      itemType: item.product.type,
      itemId: item.product.id,
      qty: item.quantity,
    );
    if (!ok) {
      await _setPendingSync(true);
    }
  }

  Future<void> _pushRemoveFromServer(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.readToken();
    final isAdmin = prefs.getBool('is_admin') ?? _isAdminMode;
    if (isAdmin || token == null || token.trim().isEmpty) return;

    final ok = await ApiService().removeCartItem(
      token,
      itemType: item.product.type,
      itemId: item.product.id,
    );
    if (!ok) {
      await _setPendingSync(true);
    }
  }

  // Tambah ke keranjang (tersimpan lokal + database)
  void addToCart(Product product) {
    if (_isAdminMode) return;

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.product.type == product.type,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
    _saveToPrefs();
    _pushAddToServer(product);
  }

  // Hapus dari keranjang
  void removeFromCart(CartItem item) {
    if (_isAdminMode) return;
    _items.remove(item);
    notifyListeners();
    _saveToPrefs();
    _pushRemoveFromServer(item);
  }

  Future<void> clearCart({bool syncServer = true}) async {
    _items.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (syncServer && !_isAdminMode) {
      final token = await SecureStorageService.readToken();
      if (token != null && token.trim().isNotEmpty) {
        final ok = await ApiService().clearCartApi(token);
        await _setPendingSync(!ok);
        return;
      }
    }
    await _setPendingSync(false);
  }

  // Tambah kuantitas (menghormati batas stok bila tersedia)
  bool increaseQuantity(CartItem item) {
    if (_isAdminMode) return false;
    if (item.product.stok > 0 && item.quantity >= item.product.stok) {
      return false;
    }
    item.quantity++;
    notifyListeners();
    _saveToPrefs();
    _pushQtyToServer(item);
    return true;
  }

  // Set kuantitas langsung (ketik manual di keranjang)
  int setQuantity(CartItem item, int requestedQty) {
    if (_isAdminMode) return item.quantity;
    int clamped = requestedQty < 1 ? 1 : requestedQty;
    if (item.product.stok > 0 && clamped > item.product.stok) {
      clamped = item.product.stok;
    }
    if (clamped == item.quantity) return clamped;
    item.quantity = clamped;
    notifyListeners();
    _saveToPrefs();
    _pushQtyToServer(item);
    return clamped;
  }

  // Kurangi kuantitas
  void decreaseQuantity(CartItem item) {
    if (_isAdminMode) return;
    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();
      _saveToPrefs();
      _pushQtyToServer(item);
    }
  }
}
