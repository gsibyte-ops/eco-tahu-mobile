import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:latlong2/latlong.dart';
import 'location_result.dart';

class _WebGeoException implements Exception {
  final int code;
  final String message;

  const _WebGeoException(this.code, this.message);
}

Future<LatLng> _requestPosition(
  JSObject geo, {
  required bool enableHighAccuracy,
  required int timeoutMs,
  required int maximumAgeMs,
}) {
  final completer = Completer<LatLng>();

  try {
    final JSFunction onSuccess = ((JSAny? posAny) {
      if (completer.isCompleted) return;
      try {
        final pos = posAny as JSObject;
        final coords = pos['coords'] as JSObject;
        final lat = (coords['latitude'] as JSNumber).toDartDouble;
        final lng = (coords['longitude'] as JSNumber).toDartDouble;
        completer.complete(LatLng(lat, lng));
      } catch (e) {
        completer.completeError(_WebGeoException(2, e.toString()));
      }
    }).toJS;

    final JSFunction onError = ((JSAny? errAny) {
      if (completer.isCompleted) return;
      try {
        final err = errAny as JSObject;
        final code = (err['code'] as JSNumber?)?.toDartInt ?? 2;
        final message = (err['message'] as JSString?)?.toDart ?? '';
        completer.completeError(_WebGeoException(code, message));
      } catch (e) {
        completer.completeError(_WebGeoException(2, e.toString()));
      }
    }).toJS;

    final options = <String, Object>{
      'enableHighAccuracy': enableHighAccuracy,
      'timeout': timeoutMs,
      'maximumAge': maximumAgeMs,
    }.jsify();

    geo.callMethod(
      'getCurrentPosition'.toJS,
      onSuccess,
      onError,
      options,
    );
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError(_WebGeoException(2, e.toString()));
    }
  }

  return completer.future.timeout(
    Duration(milliseconds: timeoutMs + 2000),
    onTimeout: () => throw const _WebGeoException(3, 'Browser geolocation timeout'),
  );
}

String _mapGeoErrorMessage(_WebGeoException err) {
  switch (err.code) {
    case 1:
      return 'Izin akses lokasi ditolak di browser. Aktifkan izin lokasi di ikon sebelah URL browser, lalu coba lagi atau ketuk manual pada peta.';
    case 2:
      return 'Lokasi perangkat tidak tersedia di browser saat ini. Aktifkan Location di pengaturan Windows/perangkat, atau ketuk manual pada peta.';
    case 3:
      return 'Waktu pencarian lokasi habis. Pastikan layanan lokasi aktif, atau ketuk manual pada peta.';
    default:
      return 'Gagal mendapatkan lokasi saat ini. Silakan ketuk manual pada peta.';
  }
}

Future<LocationResult> fetchCurrentLocation() async {
  final navAny = globalContext['navigator'];
  final geoAny = navAny is JSObject ? navAny['geolocation'] : null;
  if (geoAny is! JSObject) {
    return const LocationResult(
      errorMessage: 'Browser Anda tidak mendukung fitur lokasi. Silakan ketuk manual pada peta.',
    );
  }

  final JSObject geo = geoAny;

  try {
    final pos = await _requestPosition(
      geo,
      enableHighAccuracy: true,
      timeoutMs: 10000,
      maximumAgeMs: 60000,
    );
    return LocationResult(location: pos);
  } on _WebGeoException catch (firstErr) {
    if (firstErr.code == 1) {
      return LocationResult(errorMessage: _mapGeoErrorMessage(firstErr));
    }

    // Fallback tanpa high accuracy untuk browser desktop/Wi-Fi agar tetap dapat posisi
    try {
      final fallbackPos = await _requestPosition(
        geo,
        enableHighAccuracy: false,
        timeoutMs: 12000,
        maximumAgeMs: 300000,
      );
      return LocationResult(location: fallbackPos);
    } on _WebGeoException catch (secondErr) {
      return LocationResult(errorMessage: _mapGeoErrorMessage(secondErr));
    } catch (_) {
      return const LocationResult(
        errorMessage: 'Gagal mendapatkan lokasi saat ini. Silakan ketuk manual pada peta.',
      );
    }
  } catch (_) {
    return const LocationResult(
      errorMessage: 'Gagal mendapatkan lokasi saat ini. Silakan ketuk manual pada peta.',
    );
  }
}
