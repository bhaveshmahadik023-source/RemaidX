import 'package:latlong2/latlong.dart';

// A place the user picked (from search, GPS, or by tapping the map).
// C3 and C2 return this object back to the screen that opened them (like C1).
class PickedPlace {
  final String name; // short name, e.g. "Phoenix Marketcity"
  final String address; // rest of the address, e.g. "Viman Nagar, Pune"
  final double lat; // latitude
  final double lng; // longitude
  const PickedPlace(
      {required this.name,
      required this.address,
      required this.lat,
      required this.lng});

  // Same position as a LatLng, because the map package needs this type.
  LatLng get latLng => LatLng(lat, lng);

  // One-line text to show in the UI: "Phoenix Marketcity, Viman Nagar"
  String get label {
    if (address.isEmpty) return name;
    return '$name, ${address.split(', ').first}';
  }
}