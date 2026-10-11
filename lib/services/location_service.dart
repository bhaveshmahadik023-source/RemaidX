import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// A simple error with a message we can show to the user.
class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}

// Gets the phone's current GPS position.
class LocationService {
  static Future<LatLng> current() async {
    // 1. Is GPS turned on in phone settings?
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Location service is off');
    }

    // 2. Do we have permission? If not, ask the user.
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw LocationException('Location permission denied');
    }

    // 3. Read the position once.
    final p = await Geolocator.getCurrentPosition();
    return LatLng(p.latitude, p.longitude);
  }
}