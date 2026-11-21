import 'package:flutter/material.dart';

/// Mengatur tab aktif pada Bottom Navigation Bar (`MainScreen`) serta filter
/// kategori awal pada halaman Katalog Produk (`ProductListingScreen`).
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String _productCategoryFilter = 'Semua';

  int get currentIndex => _currentIndex;
  String get productCategoryFilter => _productCategoryFilter;

  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void setProductFilter(String filter) {
    if (_productCategoryFilter == filter) return;
    _productCategoryFilter = filter;
    notifyListeners();
  }

  void openProductsTab({String filter = 'Semua'}) {
    final changed = _currentIndex != 1 || _productCategoryFilter != filter;
    _productCategoryFilter = filter;
    _currentIndex = 1;
    if (changed) {
      notifyListeners();
    }
  }
}
