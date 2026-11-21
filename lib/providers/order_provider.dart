import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => _orders;

  OrderProvider() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('orders');
      if (ordersJson != null && ordersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(ordersJson);
        _orders.clear();
        _orders.addAll(decoded.map((item) => Order.fromJson(item)).toList());
        notifyListeners();
      }
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('orders', ordersJson);
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrders();
    notifyListeners();
  }

  void updateOrderStatus(String orderNumber, String newStatus) {
    final index = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    if (index >= 0) {
      _orders[index].status = newStatus;
      _saveOrders();
      notifyListeners();
    }
  }

  // ================= FUNGSI BARU: BATALKAN PESANAN =================
  void cancelOrder(String orderNumber, String reason) {
    final index = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    if (index >= 0) {
      _orders[index].status = 'Dibatalkan';
      _orders[index].cancelReason = reason;
      _saveOrders();
      notifyListeners();
    }
  }

  String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'EFT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }
}