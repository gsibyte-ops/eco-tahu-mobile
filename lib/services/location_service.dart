import 'location_result.dart';
import 'location_service_io.dart'
    if (dart.library.js_interop) 'location_service_web.dart' as impl;

export 'location_result.dart';

class LocationService {
  static Future<LocationResult> getCurrentLocation() => impl.fetchCurrentLocation();
}
