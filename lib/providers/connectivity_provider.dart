import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Memantau status koneksi internet secara realtime di seluruh aplikasi
/// (Guest, Pelanggan, maupun Admin) dan memicu sinkronisasi otomatis saat kembali online.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _hasCheckedInitial = false;
  bool _justReconnected = false;
  Timer? _reconnectedTimer;

  final List<Future<void> Function()> _onReconnectCallbacks = [];

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasCheckedInitial => _hasCheckedInitial;
  bool get justReconnected => _justReconnected;

  ConnectivityProvider() {
    _init();
  }

  void addReconnectListener(Future<void> Function() callback) {
    if (!_onReconnectCallbacks.contains(callback)) {
      _onReconnectCallbacks.add(callback);
    }
  }

  void removeReconnectListener(Future<void> Function() callback) {
    _onReconnectCallbacks.remove(callback);
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _applyResults(results, triggerCallbacks: false);
    } catch (_) {
      _isOnline = true;
    }
    _hasCheckedInitial = true;
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _applyResults(results, triggerCallbacks: true);
    });
  }

  void _applyResults(List<ConnectivityResult> results, {required bool triggerCallbacks}) {
    final nowOnline = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = !_isOnline;

    if (nowOnline != _isOnline) {
      _isOnline = nowOnline;
      if (nowOnline && wasOffline) {
        _justReconnected = true;
        _reconnectedTimer?.cancel();
        _reconnectedTimer = Timer(const Duration(seconds: 4), () {
          _justReconnected = false;
          notifyListeners();
        });
        if (triggerCallbacks) {
          _fireReconnectCallbacks();
        }
      } else if (!nowOnline) {
        _justReconnected = false;
        _reconnectedTimer?.cancel();
      }
      notifyListeners();
    }
  }

  /// Dipanggil manual bila request HTTP gagal karena SocketException/timeout atau berhasil kembali.
  void reportReachability(bool reachable) {
    final wasOffline = !_isOnline;
    if (reachable == _isOnline) return;
    _isOnline = reachable;
    if (reachable && wasOffline) {
      _justReconnected = true;
      _reconnectedTimer?.cancel();
      _reconnectedTimer = Timer(const Duration(seconds: 4), () {
        _justReconnected = false;
        notifyListeners();
      });
      _fireReconnectCallbacks();
    } else if (!reachable) {
      _justReconnected = false;
      _reconnectedTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _applyResults(results, triggerCallbacks: true);
    } catch (_) {}
  }

  Future<void> _fireReconnectCallbacks() async {
    for (final cb in List<Future<void> Function()>.from(_onReconnectCallbacks)) {
      try {
        await cb();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectedTimer?.cancel();
    super.dispose();
  }
}
