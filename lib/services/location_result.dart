import 'package:latlong2/latlong.dart';

class LocationResult {
  final LatLng? location;
  final String? errorMessage;

  const LocationResult({
    this.location,
    this.errorMessage,
  });

  bool get isSuccess => location != null;
}
