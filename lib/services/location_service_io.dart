import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_result.dart';

Future<LocationResult> fetchCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        errorMessage: 'Layanan GPS / Lokasi belum aktif. Aktifkan lokasi di perangkat Anda atau ketuk manual di peta.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(
        errorMessage: 'Izin akses lokasi ditolak. Izinkan akses lokasi atau ketuk manual di peta.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        errorMessage: 'Izin lokasi diblokir permanen. Aktifkan lewat pengaturan perangkat, atau ketuk manual di peta.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return LocationResult(location: LatLng(position.latitude, position.longitude));
    } catch (_) {
      try {
        final fallback = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        return LocationResult(location: LatLng(fallback.latitude, fallback.longitude));
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LocationResult(location: LatLng(lastKnown.latitude, lastKnown.longitude));
        }
        return const LocationResult(
          errorMessage: 'Gagal mendapatkan lokasi GPS. Pastikan sinyal GPS baik atau ketuk manual di peta.',
        );
      }
    }
  } catch (_) {
    return const LocationResult(
      errorMessage: 'Gagal mendapatkan lokasi saat ini. Silakan ketuk manual pada peta.',
    );
  }
}
